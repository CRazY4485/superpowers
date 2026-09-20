# Şəxsi fork — iş qaydası (yalnız Claude Code)

Bu repo [obra/superpowers](https://github.com/obra/superpowers) layihəsinin şəxsi forkudur:
[CRazY4485/superpowers](https://github.com/CRazY4485/superpowers). Upstream-in bütün
yenilikləri buraya çəkilir, şəxsi dəyişikliklər isə birbaşa `main`-də saxlanılır.
Fork yalnız **Claude Code** üçün istifadə olunur.

## Remote-lar

| Remote | Repo | Məqsəd |
| --- | --- | --- |
| `origin` | `CRazY4485/superpowers` | Şəxsi fork — plugin buradan quraşdırılır |
| `upstream` | `obra/superpowers` | Orijinal layihə — yalnız oxumaq/çəkmək üçün |

Lokal iş qovluğu: `C:\obra2`

## Quraşdırma (bu və ya yeni maşında)

```bash
claude plugin marketplace add CRazY4485/superpowers
claude plugin install superpowers@superpowers-personal
```

Claude Code daxilində eyni şey slash əmrləri ilə:

```
/plugin marketplace add CRazY4485/superpowers
/plugin install superpowers@superpowers-personal
```

Quraşdırmadan sonra Claude Code-u yenidən başlat — skill-lər hər sessiyanın
əvvəlində `SessionStart` hook-u ilə yüklənir.

## Öz dəyişikliyini etmək

1. `C:\obra2` içində redaktə et (`skills/`, `hooks/`, `docs/`, `.claude-plugin/`).
2. Manifestləri yoxla:
   ```bash
   claude plugin validate C:\obra2
   ```
3. Commit və push:
   ```bash
   git add -A
   git commit -m "..."
   git push origin main
   ```
4. Quraşdırılmış plugin-i yenilə:
   ```bash
   claude plugin marketplace update superpowers-personal
   claude plugin update superpowers@superpowers-personal
   ```
5. Claude Code-u restart et.

> Plugin GitHub-dan commit SHA ilə çəkilir — push etmədən `plugin update` heç nə
> dəyişmir. Yəni dəyişiklik əvvəlcə fork-a getməlidir.

### Niyə manifestlərdə `version` sahəsi yoxdur

Claude Code plugin-in `version` sahəsini görəndə yenilənməni ona görə qərarlaşdırır:
versiya dəyişməyibsə, yeni commit olsa belə **heç nə yükləmir**. `version` sahəsi
`.claude-plugin/plugin.json` və `.claude-plugin/marketplace.json`-dan silinib, ona görə
Claude plugin-i commit SHA ilə izləyir (rəsmi marketplace plugin-ləri də belədir) —
hər push-dan sonra `plugin update` sadəcə işləyir, əl ilə versiya artırmaq lazım deyil.

`claude plugin validate` bunu "No version specified" xəbərdarlığı kimi göstərir —
bu gözləniləndir, səhv deyil.

## Upstream yeniliklərini çəkmək

```powershell
powershell -ExecutionPolicy Bypass -File scripts\sync-upstream.ps1
```

Skript sırayla: `upstream`-i fetch edir, `upstream/main`-i `main`-ə merge edir,
fork-a xas manifestləri qoruyur (upstream-in geri qaytardığı `version` sahəsini
yenidən silir), `origin`-ə push edir və plugin-i yeniləyir.
Açarlar: `-SkipPush`, `-SkipPluginUpdate`, `-Branch <ad>`.

Eyni şeyi əl ilə:

```bash
git fetch upstream --prune
git merge --no-edit upstream/main
git push origin main
claude plugin marketplace update superpowers-personal
claude plugin update superpowers@superpowers-personal
```

Konflikt adətən yalnız `.claude-plugin/plugin.json` və
`.claude-plugin/marketplace.json` fayllarında olur (upstream versiya artırır, bizdə
o sahə yoxdur) — həll qaydası: **bizim variantı saxla** (`git checkout --ours -- <fayl>`).
Skript bunu avtomatik edir.

## Öz skill-ini əlavə etmək

Yeni qovluq + `SKILL.md` kifayətdir (yeni fayl olduğu üçün upstream ilə heç vaxt
konflikt vermir):

```
skills/<skill-adı>/SKILL.md
```

```markdown
---
name: skill-adı
description: Nə vaxt işə düşməli olduğunu izah edən bir cümlə — Claude bu mətnə baxıb qərar verir
---

# Başlıq

Addımlar və qaydalar...
```

Quraşdırıldıqdan sonra skill `superpowers:skill-adı` kimi çağırılır.
Skill yazmaq qaydaları: `skills/writing-skills/SKILL.md`.

## Layihə konteksti mexanizmi (fork-a xas)

Bu fork-a əlavə edilən mexanizm sessiyalar, compaction-lar və maşınlar arasında
layihənin kontekstini itirməməyə xidmət edir. Üzərində işlədiyin **hər bir layihədə**
işləyir, bu repo-da yox.

Layihə iştirak etmək üçün sadəcə `<layihə>/.claude/context/` qovluğuna sahib olmalıdır:

| Fayl | Nə saxlayır |
| --- | --- |
| `project.md` | Stack, qurma/test əmrləri, konvensiyalar, mühit tələləri |
| `state.md` | İş harada dayanıb, növbəti addım, açıq suallar |
| `decisions.md` | Qərarlar, səbəbləri, rədd edilmiş alternativlər (yalnız əlavə olunur) |

İstifadə:

```
/superpowers:context-init     # layihə üçün faylları yaradır və doldurur
/superpowers:context-save     # cari vəziyyəti və qərarları indi yazır
```

Necə işləyir:

- **Hər sessiyanın əvvəlində** `project.md` + `state.md` tam şəkildə konteksə yüklənir,
  `decisions.md` isə yalnız xülasə olaraq (say + son 3 başlıq). Matcher `startup|clear|compact`
  olduğuna görə üç itki yolunun hamısı örtülür: **yeni sessiya** (yeni terminal, başqa gün,
  başqa maşın), **`/clear`** və **compaction**.
- **Reality check:** blokun sonunda `state.md` yazıldıqdan sonra repo-da nə baş verdiyi
  göstərilir — neçə commit (son 5-in başlığı) və neçə fayl uncommitted. Yəni köhnəlmiş
  `state.md`-ə kor-koranə etibar edilmir, əvvəlcə uzlaşdırılır.
- **Cavab bitəndə** (`Stop` hook) `state.md` işdən geri qalıbsa (yeni commit var, yaxud
  ağac uzun müddət dirty-dir) xatırlatma inject olunur. Bloklamır, spam etmir —
  layihə başına throttle var.
- `.claude/context/` olmayan layihələrdə heç nə dəyişmir: nə inject, nə xatırlatma.

Detallar və nizamlayıcı dəyişənlər: `docs/project-context.md`.
Yazı qaydaları: `skills/maintaining-project-context/SKILL.md`.

Testlər:

```bash
bash tests/hooks/test-project-context.sh
bash tests/hooks/test-session-start.sh
```

## Müsahibə reyestri (fork-a xas)

Uzun sual-cavab prosesində cavabların itməsinə qarşı. Problem iki ayrı
mexanizmdən ibarətdir və hər ikisi bağlanıb:

- **Diqqət seyrəlməsi** — 20-ci sualda 3-cü cavab hələ kontekstdədir, amma çəkisi
  itib. Həlli: açıq və ertələnmiş bəndlər `UserPromptSubmit` hook-u ilə **hər mesajda**
  kontekstin ən yeni mövqeyinə yenidən yazılır.
- **Ertələnmiş mövzular** — "sonra qərarlaşdırarıq" bir dəfə deyilir və yox olur.
  Həlli: `[deferred: <tətik>]` statusu tətiksiz qəbul edilmir və bənd həll olunana
  qədər hər mesajda görünür.

Reyestr: `.claude/context/interview.md`. Statuslar: `[open]`, `[answered]`,
`[deferred: <tətik>]`, `[superseded by Qnn]`. Cavablar **istifadəçinin öz sözləri ilə**
sitat şəklində yazılır.

```
/superpowers:interview-status    # nə cavablanıb, nə açıqdır, nə ertələnib
/superpowers:interview-close     # qapanış: qərarlar decisions.md-ə, ertələnənlər state.md-ə
```

Əlavə qaydalar skill-in içindədir: hər ~5 cavabdan sonra recap (insan düzəliş etsin),
spec/plan/yekun yazmazdan əvvəl **coverage gate** (hər bənd ya əks olunub, ya açıq
ertələnib, ya da səbəbi ilə köhnəlib).

Cavab yazılmadığında: hook əvvəlki mesajdan bəri reyestrin dəyişmədiyini görürsə,
"əvvəlki cavabı yaz" xəbərdarlığı inject edir. Hook modeli yazmağa məcbur edə bilmir —
yalnız unutmağı görünən edir.

Detallar: `docs/interview-ledger.md`.

## Git checkpoint-ləri və təhlükəli əmr qoruyucusu (fork-a xas)

Commit edilməmiş işi geri qaytarıla bilən edir. Checkpoint — **müvəqqəti index**
üzərindən qurulan adi git commit-idir, `refs/superpowers/checkpoints/` altında saxlanılır:

- İzlənən dəyişiklikləri **və** untracked faylları tutur (`.gitignore`-a hörmətlə).
- Heç nəyə toxunmur: iş ağacı, index, HEAD, branch — hamısı olduğu kimi qalır.
  `git status`, `git log` dəyişmir, `git push` bu ref-ləri göndərmir.
- Adi commit olduğu üçün tanış alətlər işləyir: `git diff HEAD <sha>`,
  `git show <sha>:fayl`, `git checkout <sha> -- fayl`.

Nə vaxt götürülür:

| Tətik | Hook | Etiket |
| --- | --- | --- |
| Hər cavabın sonunda | `Stop` (async) | `turn` |
| İşi silə bilən Bash əmrindən **əvvəl** | `PreToolUse` (matcher `Bash`) | `pre-destructive` |

Qoruyucu iki sinif əmri tanıyır (`Bash` və `PowerShell` alətlərində):

- **git:** `reset --hard/--merge/--keep`, `checkout -- `, `restore`, `clean -f*`,
  `stash drop|clear|pop`, `branch -D`, `rebase`, `commit --amend`, `push --force`.
  İtiriləcək bir şey yoxdursa, bunu da deyir (əməliyyatın təhlükəsiz olduğunu bilmək dəyərlidir).
- **kütləvi silmə:** `rm -r*/-f*`, `shred`, `truncate -s`, `find … -delete`,
  `find … -exec rm`, `Remove-Item … -Recurse/-Force`, `Clear-Content`, `rmdir /s`, `del /s|/q`.
  Bunlar tez-tez işlənir, ona görə itki riski yoxdursa səssiz qalır.
  Tək fayllıq `rm notes.txt` qəsdən və dardır — toxunulmur.

**Bloklamır** — əvvəlcə checkpoint götürür və sha ilə bərpa əmrlərini kontekstə yazır.
Qəsdən yazılmış əmri bloklamaq maneədir; commit edilməmiş işi itirmək isə ziyandır —
mexanizm ikincini birinciyə çevirir.

**Commit xatırlatması** (`Stop`): ağac son commit-dən uzaqlaşıbsa — ən azı 5 fayl
dəyişib, yaxud son commit-dən 45 dəqiqədən çox keçib və ağac dirty-dir — görünən
xəbərdarlıq gəlir. Untracked fayllar sayılır, ignored fayllar yox; layihə başına throttle.
Səbəb: **checkpoint qeyd deyil** — lokaldır, budanır, partnyorun görmür.

**Tarixçə ilə istintaq:** `superpowers:investigating-with-git-history` —
`git bisect run` ilə ilk sınıq commit-i tapmaq, `log -S` ilə sətrin haradan gəldiyini
görmək, `blame` → sha → commit mesajı ilə "niyə belədir" sualını cavablandırmaq.
`systematic-debugging`-in 1-ci fazasından ona keçid qoyulub.

```
/superpowers:checkpoints          # siyahı + bərpa axını
git diff HEAD <sha>               # nə fərq var
git checkout <sha> -- <fayl>      # bir faylı geri qaytar
```

Skill: `superpowers:recovering-work-with-git` — commit tezliyi, hansı "undo"-nun
hansı tarixçədə təhlükəsiz olduğu (`revert` vs `reset --soft` vs `--hard`) və
**bərpa nərdivanı**: checkpoint → reflog → stash → `fsck --lost-found`.

Detallar və limitlər: `docs/git-checkpoints.md`.

## Commit qapısı, branch qoruyucusu və eval-lar (fork-a xas)

**Commit qapısı** (`PreToolUse`, `git commit` əmrində): staged diff-ə baxır.
Buradakı yeganə **bloklayan** mexanizmdir, çünki hər ikisi tarixçəyə düşəndən sonra
bahalıdır:

| Tapıntı | Nəticə |
| --- | --- |
| Həll olunmamış konflikt markerləri | **blok** |
| AWS açarı, private key bloku, GitHub/Slack token, `sk-` API açarı | **blok** |
| `password = "..."` tipli literal | xəbərdarlıq |
| 5 MB-dan böyük staged fayl | xəbərdarlıq |

Tapıntılar **adı və yeri ilə** bildirilir, dəyəri ilə yox — sirri transkriptə yazmaq
onun daha bir nüsxəsini yaratmaq deməkdir.

**Branch qoruyucusu** (`PreToolUse`, `Edit|Write`): layihə içindəki redaktə default
branch-də (origin/HEAD, yoxsa `main`/`master`/`trunk`) baş verirsə, saatda bir dəfə
xatırladır. Bloklamır — bəzən məhz `main`-ə düzəliş istənir.

**Merge konflikti:** `superpowers:resolving-merge-conflicts` — iki mətni deyil,
**iki niyyəti** uzlaşdırmaq; `zdiff3`, lockfile-ları yenidən generasiya etmək,
`rerere`, və anlamırsansa `merge --abort` (pulsuzdur). `finishing-a-development-branch`
merge addımından ona keçid qoyulub.

**Eval-lar** (`plugin-evals/`): skill-lərin real sessiyada tutub-tutmadığını ölçür.

```bash
claude plugin eval C:/obra2 --runs 1 --ablation none --trust-plugin --no-publish
```

İlk işlətmə iki qüsur tapdı: biri eval-ın özündə (case Write aləti vermirdi),
**biri isə skill-də** — agent `reset --hard`+`clean -fd` ilə başlayıb `stash -u`-nu
sonda qeyd edirdi; insan ona verilən **ilk** bloku işlədir. `recovering-work-with-git`
indi qoruyan əmrin birinci gəlməsini tələb edir. Detallar: `docs/evals.md`.

## Araşdırma mənbələri (fork-a xas)

**Qayda:** xarici API, kitabxana, CLI və ya versiya davranışı sual altındadırsa,
cavab **vendorun öz sənədindən** gəlir; yaddaşdan və bloqdan yox.

`superpowers:researching-with-official-docs` skill-i bunu daşıyır:

- **Playwright MCP ilə brauzerdən** getmək (`browser_navigate`, sonra hədəfli
  `browser_evaluate`) — çünki müasir sənəd səhifələri JS ilə render olunur və adi
  fetch boş qabıq qaytarır.
- Tam accessibility snapshot-u oxumaq əvəzinə lazım olan bölməni çıxarmaq
  (bir sənəd səhifəsinin snapshot-u yüz kilobaytlarladır).
- Mənbə iyerarxiyası: rəsmi sənəd → layihənin repo-su (CHANGELOG, mənbə kod) →
  rəsmi bloq → icma (Stack Overflow, bloqlar) — sonuncu **yalnız ipucudur**,
  cavab deyil, istifadə olunursa bu açıq deyilməlidir.
- Cavabda **URL sitat gətirmək**, dəqiqlik vacibdirsə sxemi **eynilə** vermək,
  sonradan lazım olacaqsa `.claude/context/`-ə yazmaq.
- `.playwright-mcp/` qovluğu `.gitignore`-da olmalıdır (MCP hər naviqasiyada ora
  böyük snapshot yazır).

**Hook:** `WebFetch`/`WebSearch` çağırılanda saatda bir dəfə brauzerə və rəsmi
sənədə yönləndirən xatırlatma inject olunur. Bloklamır — statik səhifə üçün
sadə fetch bəzən doğru seçimdir.

**Eval:** `plugin-evals/official-docs` — "hansı hook-lar kontekst inject edə bilir,
dəqiq JSON şəkli nədir?" sualına yaddaşdan qəti cavab verilməsi uğursuzluq sayılır.

## Hansı qovluqlar əhəmiyyətlidir

Claude Code üçün yalnız bunlar işləyir:

- `skills/` — bütün skill-lər (əsas iş burada gedir)
- `.claude-plugin/` — plugin və marketplace manifestləri
- `hooks/` — `SessionStart` hook-u (`superpowers:using-superpowers` skill-ini yükləyir)
- `docs/`, `README.md`, `AGENTS.md` — sənədlər

Digər harness-lərə aid qovluqlar (`.codex-plugin/`, `.cursor-plugin/`, `.devin-plugin/`,
`.kimi-plugin/`, `.muse-plugin/`, `.hermes-plugin/`, `.opencode/`, `.pi/`, `.agents/`,
`gemini-extension.json`) Claude Code-da heç bir rol oynamır. Bilərəkdən silinməyib:
toxunulmadıqları üçün upstream merge-lərində konflikt yaratmırlar. Repo-nu kiçiltmək
istəsən, onları silmək olar — amma sonrakı hər upstream yeniliyində "deleted by us"
konfliktləri çıxacaq.

`scripts/bump-version.sh` upstream-in reliz alətidir — bu fork-da istifadə olunmur.

## Fork-a xas dəyişikliklər (upstream-dən fərq)

- `.claude-plugin/marketplace.json` — marketplace adı `superpowers-personal`, sahib CRazY4485, `version` yoxdur
- `.claude-plugin/plugin.json` — `homepage`/`repository` fork-a baxır, `version` yoxdur
- `scripts/sync-upstream.ps1` — upstream sinxronizasiya skripti
- `PERSONAL.md` — bu sənəd
- `skills/maintaining-project-context/` — layihə konteksti skill-i və şablonlar
- `skills/keeping-an-interview-ledger/` — müsahibə reyestri skill-i və şablon
- `skills/recovering-work-with-git/` — commit tezliyi, undo seçimi, bərpa nərdivanı
- `skills/investigating-with-git-history/` — bisect, `log -S`, blame ilə sübut toplamaq
- `skills/resolving-merge-conflicts/` — konfliktləri niyyət səviyyəsində həll etmək
- `skills/researching-with-official-docs/` — rəsmi sənəd + Playwright MCP ilə araşdırma
- `hooks/project-context`, `hooks/context-nudge`, `hooks/interview-context` — inject və xatırlatma hook-ları
- `hooks/git-checkpoint`, `hooks/checkpoint-turn`, `hooks/git-guard`, `hooks/commit-nudge` — checkpoint mühərriki, turluq snapshot, təhlükəli əmr qoruyucusu, commit xatırlatması
- `hooks/commit-gate`, `hooks/branch-guard`, `hooks/research-nudge` — sirr/konflikt/böyük fayl qapısı, default branch və araşdırma mənbəyi xatırlatmaları
- `plugin-evals/` — davranış eval-ları (4 case), `docs/evals.md`
- `commands/` — `context-init`, `context-save`, `interview-status`, `interview-close`, `checkpoints`
- `docs/project-context.md`, `docs/interview-ledger.md`, `docs/git-checkpoints.md` — sənədlər
- `tests/hooks/test-project-context.sh`, `test-interview-ledger.sh`, `test-git-checkpoint.sh`, `test-commit-nudge.sh`, `test-commit-gate.sh`, `test-research-nudge.sh` — testlər

**Upstream fayllarına toxunulan yerlər** (merge zamanı konflikt ehtimalı olan siyahı —
yenilik gələndə əvvəlcə bunlara bax):

| Fayl | Nə əlavə edilib |
| --- | --- |
| `hooks/session-start` | Kontekst blokunun inject edilməsi |
| `hooks/hooks.json` | `Stop` (3 giriş), `UserPromptSubmit` və `PreToolUse` hook-larının qeydiyyatı |
| `skills/systematic-debugging/SKILL.md` | 1-ci fazada tarixçə istintaqı skill-inə keçid |
| `skills/finishing-a-development-branch/SKILL.md` | Merge addımında konflikt skill-inə keçid |
| `skills/brainstorming/SKILL.md` | "Record What They Tell You" bölməsi, 2 checklist bəndi, 2 red-flag sətri, coverage gate |
| `skills/writing-plans/SKILL.md` | "Ledger Coverage" bölməsi |
| `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` | Fork kimliyi, `version` sahəsinin silinməsi |
| `.gitattributes` | Yeni hook faylları üçün LF qaydası |

Plugin adı bilərəkdən `superpowers` olaraq qalıb: skill namespace-i
(`superpowers:brainstorming` və s.) və sənədlərdəki istinadlar ondan asılıdır.
