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
- `hooks/project-context`, `hooks/context-nudge` — kontekst inject + köhnəlmə xatırlatması
- `hooks/session-start`, `hooks/hooks.json` — kontekst blokunun və `Stop` hook-unun qoşulması
- `commands/context-init.md`, `commands/context-save.md` — slash əmrləri
- `docs/project-context.md`, `tests/hooks/test-project-context.sh` — sənəd və testlər

Plugin adı bilərəkdən `superpowers` olaraq qalıb: skill namespace-i
(`superpowers:brainstorming` və s.) və sənədlərdəki istinadlar ondan asılıdır.
