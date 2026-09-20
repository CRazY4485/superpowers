# Şəxsi fork — operator təlimatı (yalnız Claude Code)

Bu repo [obra/superpowers](https://github.com/obra/superpowers) layihəsinin şəxsi
forkudur: [CRazY4485/superpowers](https://github.com/CRazY4485/superpowers).
Upstream yenilikləri buraya çəkilir, şəxsi dəyişikliklər birbaşa `main`-dədir.

Bu sənəd **indeksdir**: nə etməli olduğunu və detalın harada olduğunu göstərir.
Hər mexanizmin izahı `docs/` altında **bir dəfə** yazılıb — burada təkrarlanmır.

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

Sonra Claude Code-u **restart et** — skill-lər sessiya başlayanda `SessionStart`
hook-u ilə yüklənir.

## Öz dəyişikliyini etmək

```bash
# 1. C:\obra2 içində redaktə et
claude plugin validate C:\obra2          # 2. manifestləri yoxla
bash tests/hooks/<dəyişdiyin>.sh         # 3. aid olan testi işlət
git add -A && git commit -m "..." && git push origin main
claude plugin marketplace update superpowers-personal
claude plugin update superpowers@superpowers-personal
# 4. Claude Code-u restart et
```

> Plugin commit SHA ilə çəkilir — **push etmədən** `plugin update` heç nə dəyişmir.
> Manifestlərdə `version` sahəsinin niyə olmadığı: `docs/upstream-register.md`.

## Upstream yeniliklərini çəkmək

```powershell
powershell -ExecutionPolicy Bypass -File scripts\sync-upstream.ps1
```

Skript əvvəlcə **upstream reyestrini** çap edir (hansı upstream fayllarına
toxunmuşuq və konflikt olarsa necə həll edilməli), sonra fetch → merge → push →
plugin update edir. Açarlar: `-SkipPush`, `-SkipPluginUpdate`, `-Branch <ad>`.

Reyestri ayrıca da görmək olar:

```bash
bash scripts/upstream-register.sh          # siyahı + hər fayl üçün qayda
bash scripts/upstream-register.sh --full   # üstəgəl fork-un əlavə etdiyi sətirlər
```

Qaydalar və fork xərcini aşağı saxlamaq prinsipi: **`docs/upstream-register.md`**.

## Mexanizmlər

Hamısı işlədiyin **layihələrdə** işləyir, bu repo-da yox. Detal sütundakı sənəddədir.

| Mexanizm | Bir cümlə ilə | Detal |
| --- | --- | --- |
| Layihə konteksti | `.claude/context/` faylları hər sessiyada — `/clear` və compaction daxil — yenidən yüklənir; blokun sonunda repo ilə **reality check** | `docs/project-context.md` |
| Müsahibə reyestri | Uzun sual-cavabda açıq və ertələnmiş bəndlər **hər mesajda** kontekstin ən yeni mövqeyinə qayıdır | `docs/interview-ledger.md` |
| Git checkpoint-ləri | Hər turda və təhlükəli əmrdən əvvəl iş ağacının tam snapshot-u; `git status`/`log`/`push` dəyişmir | `docs/git-checkpoints.md` |
| Commit qapısı | Sirr və konflikt markerləri **bloklanır**; şübhəli literal və böyük fayl xəbərdarlıq | `docs/git-checkpoints.md` |
| Test bütövlüyü | Skip/`.only`/test itkisi **bloklanır**; assertion itkisi və "keçə bilməyən test" xəbərdarlıq | `docs/test-integrity.md` |
| TDD döngə limiti | Eyni testin 3-cü uğursuzluğunda diaqnoz, 6-cıda dayan-və-hesabat; sub-agent həll olunmamış döngə ilə qayıdırsa valideyn xəbərdar edilir | `docs/tdd-loop-budget.md` |
| Qərar bütövlüyü | Əsassız və ya fərziyyəyə söykənən qərar qeydi **bloklanır**; eyni scope-da iki aktiv qərar uzlaşdırmaya göndərilir | `docs/decision-integrity.md` |
| Sənəd həyat dövrü | Spec/plan status + törəmə bağı ilə doğulur; spec plandan sonra dəyişibsə aşkarlanır; geriyə qayıtma qeydlə baş verir | `docs/document-lifecycle.md` |
| Kodlaşdırma standartı | Konstitusiya (sənin sənədin) bağlayıcıdır; kənaraçıxma sahibin təsdiqi və qərar qeydi tələb edir | `docs/standards-and-briefs.md` |
| Sub-agent brifinqi | Göndərişdən əvvəl beş hissənin (məqsəd, sərhəd, oxunacaqlar, yoxlama, hesabat) çatışmayanları sadalanır | `docs/standards-and-briefs.md` |
| Araşdırma mənbələri | `WebFetch`/`WebSearch` çağırılanda brauzerə və rəsmi sənədə yönləndirmə | `docs/research-sources.md` |
| Branch qoruyucusu | Default branch-də redaktə saatda bir dəfə xatırladılır (bloklamır) | `docs/git-checkpoints.md` |

Slash əmrləri: `/superpowers:context-init`, `context-save`, `interview-status`,
`interview-close`, `checkpoints`, `decision-audit`, `doc-audit`, `rework`,
`constitution-init`.

## Yoxlama

```bash
for t in tests/hooks/*.sh; do bash "$t"; done      # hook testləri
claude plugin eval C:/obra2 --runs 1 --ablation with-without --trust-plugin --no-publish
```

Hook testləri skriptlərin özünü sübut edir; **harness-in davranışını yox** — bunun
niyə vacib olduğu və real sessiya smoke testinin nə tapdığı `docs/evals.md`-dədir.
Eval nəticələri və ablation rəqəmləri də orada.

## Öz skill-ini əlavə etmək

`skills/<ad>/SKILL.md` + frontmatter (`name`, `description`). Yeni fayl olduğu üçün
upstream ilə **heç vaxt konflikt vermir** — fork xərcini aşağı saxlamağın əsas yolu
budur. Qaydalar: `skills/writing-skills/SKILL.md`.

## Hansı qovluqlar əhəmiyyətlidir

`skills/`, `hooks/`, `commands/`, `.claude-plugin/`, `docs/`, `tests/hooks/`,
`plugin-evals/`, `scripts/`.

Digər harness qovluqları (`.codex-plugin/`, `.cursor-plugin/`, `.kimi-plugin/`,
`.pi/`, `.opencode/` və s.) Claude Code-da rol oynamır. Bilərəkdən silinməyib:
toxunulmadıqları üçün merge-də konflikt yaratmırlar.

`scripts/bump-version.sh` upstream-in reliz alətidir — bu fork-da işlədilmir.
