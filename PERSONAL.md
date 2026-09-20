# Şəxsi fork — operator təlimatı (yalnız Claude Code)

Bu repo [obra/superpowers](https://github.com/obra/superpowers) layihəsinin şəxsi
forkudur: [CRazY4485/superpowers](https://github.com/CRazY4485/superpowers).
Upstream yenilikləri buraya çəkilir, şəxsi dəyişikliklər birbaşa `main`-dədir.

Bu sənəd **indeksdir**: nə etməli olduğunu və detalın harada olduğunu göstərir.
Hər mexanizmin izahı `docs/` altında **bir dəfə** yazılıb — burada təkrarlanmır.

## Bu fork nədir və nə deyil

**Bu repo-nun məqsədi:** framework-ü təkmilləşdirərək **şəxsi istifadəyə yararlı
hala gətirmək**. Yəni burada görülən iş orijinalın özünə töhfə vermək deyil,
öz iş üslubuna uyğun, öz layihələrində etibarlı işləyən bir alət qurmaqdır.
Orijinalla uyğunluq yalnız bir şeyə lazımdır: onun düzəlişlərindən faydalanmaq.

Repo **xüsusi təkmilləşdirmə və şəxsi istifadə üçün** fork edilib. İşlədilən
yeganə framework budur: **orijinal `obra/superpowers` heç bir zaman quraşdırılmır
və istifadə edilmir** — nə rəsmi marketplace-dən, nə `obra/superpowers-marketplace`-dən.
Bütün maşınlarda plugin yalnız `CRazY4485/superpowers`-dən quraşdırılır.

`upstream` remote-unun **tək bir məqsədi** var: orijinalın düzəlişlərini və
təkmilləşdirmələrini **bu fork-un içinə çəkmək**. Orijinaldan istifadə etmək demək
deyil. Əgər bir gün upstream yeniliklərini də çəkməmək qərarına gəlinsə, onda
`upstream` remote-u, `scripts/sync-upstream.ps1` və `scripts/upstream-register.sh`
**silinməlidir** — işlənməyən mexanizmi "hər ehtimala qarşı" saxlamaq bu fork-un
öz qaydalarına ziddir.

| Remote | Repo | Məqsəd |
| --- | --- | --- |
| `origin` | `CRazY4485/superpowers` | **İşlədilən framework** — plugin yalnız buradan quraşdırılır |
| `upstream` | `obra/superpowers` | Yalnız yenilik mənbəyi — fork-a çəkmək üçün, istifadə üçün yox |

Lokal iş qovluğu: `C:\obra2`

## Quraşdırma (bu və ya yeni maşında)

```bash
claude plugin marketplace add CRazY4485/superpowers
claude plugin install superpowers@superpowers-personal
```

Sonra Claude Code-u **restart et** — skill-lər sessiya başlayanda `SessionStart`
hook-u ilə yüklənir.

### Ön şərtlər (yeni cihazda mütləq yoxla)

Yuxarıdakı iki əmr plugin-i quraşdırmaq üçün kifayətdir, amma **mexanizmlərin
işləməsi üçün** maşında bunlar olmalıdır:

| Lazımdır | Nə üçün | Yoxdursa nə olur |
| --- | --- | --- |
| **git** | Marketplace klonu, checkpoint-lər, bütün qapılar | Heç nə işləmir |
| **bash** (Windows-da Git for Windows) | `run-hook.cmd` onunla işləyir | **Heç bir hook işləmir** |
| **node** | 6 hook payload-u onunla parse edir | Təhlükəli əmr qoruyucusu, commit qapıları, brifinq yoxlaması, araşdırma xatırlatması və TDD döngə limiti **səssizcə sıradan çıxır** |
| Playwright MCP (opsional) | Araşdırma siyasəti | Skill qalır, brauzer yoxdur |

Bir əmrlə hamısını yoxla — Claude Code daxilindən:

```
/superpowers:doctor
```

və ya terminaldan:

```bash
bash scripts/doctor.sh
```

`node` tapılmasa, sessiya başında **xəbərdarlıq inject olunur** — yəni qorumaların
işləmədiyini təxmin etmək lazım gəlmir, sənə deyilir. Node başqa yerdədirsə:
`SUPERPOWERS_NODE_BIN` dəyişəni ilə yolunu göstər.

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

### Niyə reyestr və sync skripti var (hər dəfə düşünməmək üçün)

Qərar belədir: **upstream-dən ayrılmırıq**, çünki orijinal hələ də real düzəlişlər
verir (Windows hook düzəlişləri, skill kökləmələri, yeni harness dəstəyi) və onları
çəkmək bir əmrlik işdir. Amma bunun bir qiyməti var və reyestr məhz o qiyməti
idarə etmək üçündür:

- Bu fork-un əlavə etdiyi şeylərin **böyük hissəsi yeni fayllardır** — onlar merge
  zamanı heç vaxt konflikt vermir.
- **13 yerdə** isə upstream-in öz faylına toxunulub (göstərici abzasları, hook
  qeydiyyatı). Upstream yeni reliz buraxanda konflikt **yalnız orada** olacaq.
- Reyestr həmin siyahını **hesablayır** (saxlamır, ona görə köhnələ bilmir) və hər
  fayl üçün həll qaydasını əvvəlcədən verir; `--full` isə bizim əlavə etdiyimiz
  sətirləri çap edir — konflikt anında hazır reseptdir.

**Sənin yadda saxlamalı olduğun heç nə yoxdur:** `sync-upstream.ps1` reyestri
merge-dən əvvəl özü çap edir. Praktikada bu o deməkdir ki, upstream yeniliyi
çəkmək hər dəfə eyni mexaniki addım olur, tapmaca yox.

Fork xərcini aşağı saxlamağın qaydası da sadədir: mümkün olanda **yeni fayl** yarat;
upstream faylına toxunmalı olsan, dəyişiklik **kiçik və əlavə xarakterli** olsun.
Bu siyahı 13-dən 40-a çıxarsa, bu, artıq ayrılmaq üçün siqnaldır.

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

Slash əmrləri: `/superpowers:doctor`, `context-init`, `context-save`,
`interview-status`, `interview-close`, `checkpoints`, `decision-audit`,
`doc-audit`, `rework`, `constitution-init`.

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
