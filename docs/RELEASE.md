# KidCost - przygotowanie release dla sklepow

Data: 2026-06-24

Ten dokument zbiera minimalne decyzje, dostepy, aktywa i checklisty potrzebne do uruchomienia Google Play Internal Testing i Apple TestFlight.

## Decyzje release MVP

- Android package name: `pl.kidcost.app`
- iOS bundle id: `pl.kidcost.app`
- Nazwa aplikacji w sklepach: `KidCost`
- Pierwszy release: beta przez Google Play Internal Testing i Apple TestFlight, bez publicznej publikacji w App Store ani Google Play Production.
- Supabase dla pierwszego release: osobny projekt `prod` albo `beta-prod`, nie lokalny ani wspolny `dev`.
- Observability MVP: aplikacja ma wspolny interfejs telemetryczny, allowliste parametrow i flagi builda; Firebase Analytics/Crashlytics wlaczamy dopiero po dodaniu prawdziwego projektu Firebase i plikow platformowych poza repo.
- Platnosci/subskrypcje: poza zakresem pierwszego release.

Uzasadnienie Supabase: nawet testerzy wewnetrzni moga wpisac dane rodzinne, finansowe i zalaczniki. Srodowisko pierwszej bety powinno miec stabilne migracje, RLS, prywatny Storage i kopie zapasowe, a nie byc resetowanym razem z pracami developerskimi.

## Internal Testing i TestFlight vs publiczna publikacja

### Google Play Internal Testing

Cel: szybka dystrybucja AAB do malej grupy testerow technicznych i zaufanych uzytkownikow.

Wymagane minimum:

- konto Google Play Console z dostepem do aplikacji,
- aplikacja utworzona w Play Console z package name `pl.kidcost.app`,
- Android App Bundle podpisany kluczem release,
- track `Internal testing`,
- lista testerow albo grupa e-mail,
- privacy policy URL, jesli aplikacja zbiera dane osobowe lub uzywa uprawnien wymagajacych polityki,
- podstawowe deklaracje App content, zwlaszcza data safety, ads, target audience, sign-in details i contact details.

Internal testing nie jest publicznym listingiem produkcyjnym. Czesc ustawien Play Console moze byc jeszcze robocza, ale release nie powinien isc do testerow bez privacy/support URL i bez jasnej informacji, jakie dane sa zbierane.

### Apple TestFlight

Cel: dystrybucja builda iOS do testerow przez App Store Connect.

Wymagane minimum:

- aktywne Apple Developer Program,
- aplikacja utworzona w App Store Connect z bundle id `pl.kidcost.app`,
- build wyslany z Xcode albo CI,
- TestFlight tab z informacja `What to Test`,
- kontakt e-mail do feedbacku,
- internal tester group dla osob z dostepem App Store Connect albo external tester flow, jesli testuja osoby spoza zespolu,
- beta app review, jezeli build ma trafic do external testers.

Internal TestFlight i external TestFlight roznia sie procesem. Internal testers sa czlonkami zespolu w App Store Connect. External testers moga wymagac review pierwszego builda, wiec nie planujemy publicznej akceptacji App Store jako warunku day-3 demo.

### Publiczna publikacja

Publiczny release wymaga dodatkowo:

- kompletnego store listingu,
- finalnych screenshotow dla wymaganych rozmiarow,
- pelnych deklaracji prywatnosci i data safety,
- finalnej kategorii, ratingu wiekowego i metadanych,
- review Apple App Store albo produkcyjnego review Google Play,
- procesu obslugi supportu po wydaniu.

Publiczna publikacja nie jest celem pierwszych 3 dni.

## Konta i dostepy

| Obszar | Wymagany dostep | Minimalna rola |
| --- | --- | --- |
| Apple Developer | Certificates, Identifiers & Profiles, App Store Connect | Account Holder/Admin/App Manager albo Developer do buildow |
| Google Play Console | Tworzenie aplikacji, release tracks, App content | Admin albo release manager |
| Firebase | Crashlytics i analytics dla Android/iOS | Editor dla projektu Firebase |
| Supabase | Projekt beta/prod, Auth, Database, Storage, Edge Functions | Owner/Admin dla konfiguracji, ograniczony service role w sekretach |
| DNS/web | Publikacja privacy/support/terms | Dostep do domeny `kidcost.app` albo hostingu statycznego |
| GitHub/CI | Sekrety buildow i release automation | Admin repo albo maintainer CI |

Zasada: dostep service role, signing keys i certyfikaty maja byc w narzedziach platformy albo CI secrets, nigdy w repozytorium.

## Decyzja dla issue #35

Na obecnym etapie nie budujemy jeszcze osobnej aplikacji `apps/web`. Zrodlem tresci pozostaja pliki `docs/web/*.md`, a docelowe linki do store metadata sa gotowe do publikacji pod domena `kidcost.app`.

## Aktywy web i docelowe URL

| Aktyw | Docelowy URL do sklepu | Plik z trescia |
| --- | --- | --- |
| Privacy policy | `https://kidcost.app/privacy` | `docs/web/privacy-policy.md` |
| Support/contact | `https://kidcost.app/support` | `docs/web/support.md` |
| Terms of service | `https://kidcost.app/terms` | `docs/web/terms-of-service.md` |
| App description source | `https://kidcost.app/app` | `docs/web/app-description.md` |

Gotowy statyczny pakiet do publikacji znajduje sie w `docs/web/site/`.
Wystawienie tego katalogu jako root statycznego hostingu daje sciezki
`/privacy/`, `/support/`, `/terms/` i `/app/` bez potrzeby budowania osobnej
aplikacji webowej.

Minimalne URL dla pierwszego release:

- Privacy policy: `https://kidcost.app/privacy`
- Support: `https://kidcost.app/support`
- Terms: `https://kidcost.app/terms`

Te URL musza byc publicznie dostepne przed wyslaniem builda do testerow zewnetrznych albo przed Play review. Dla internal-only smoke testow moga byc opublikowane jako proste statyczne strony bez pelnej aplikacji webowej.

## Copy-paste do store listingow

- Privacy policy URL: `https://kidcost.app/privacy`
- Support URL: `https://kidcost.app/support`
- Support e-mail: `support@kidcost.app`
- Privacy e-mail: `privacy@kidcost.app`
- Krótki opis aplikacji: `Wspolna historia kosztow dziecka, dowodow i rozliczen w jednym miejscu.`

## Minimalny zestaw treści wymaganych przez sklepy

1. Polityka prywatnosci i data policy:
   - Zakres danych: konto, rodzina, dzieci, wydatki, statusy, zalaczniki, analytics i crash reports.
   - Przejrzysty opis widoczności danych.
   - Wersja bez obietnic szyfrowania end-to-end i bez porady prawnej.
2. Strona support/contact:
   - Kontakt e-mailowy.
   - Krótkie FAQ (co to jest i jak uzyskać pomoc).
   - Czas reakcji supportu.
3. Opis aplikacji:
   - 1 akapit celu produktu.
   - 6-8 punktów korzyści.
   - Krótki fragment do store listingów.

## Aktywa aplikacji

### Wspolne

- nazwa: `KidCost`,
- krotki opis,
- dlugi opis,
- support e-mail: `support@kidcost.app`,
- privacy e-mail: `privacy@kidcost.app`,
- kategoria: parenting/family albo finance, do potwierdzenia po store setup,
- lista znanych ograniczen bety,
- instrukcja testow: logowanie, dodanie kosztu, dodanie zalacznika, sprawdzenie salda.

### Android

- adaptive icon dla aplikacji,
- monochrome icon, jesli target Android i launcher tego wymagaja,
- splash screen,
- Google Play feature graphic, jezeli listing tego wymaga,
- screenshoty telefonu Android dla store listingu, gdy przechodzimy poza czysto internal smoke test,
- release AAB podpisany kluczem release,
- version code i version name.

### iOS

- app icon 1024x1024 bez przezroczystosci,
- launch screen/splash zgodny z iOS,
- screenshoty iPhone dla publicznego listing/review,
- bundle display name `KidCost`,
- build number i marketing version,
- export compliance odpowiedz w App Store Connect, jesli Apple poprosi o szyfrowanie.

## Checklisty buildow

### Konfiguracja builda i observability

Minimalne parametry builda przekazywane przez `--dart-define`:

```sh
--dart-define=KIDCOST_RELEASE_CHANNEL=demo
--dart-define=KIDCOST_BUILD_NAME=1.0.0
--dart-define=KIDCOST_BUILD_NUMBER=1
--dart-define=KIDCOST_ANALYTICS_ENABLED=false
--dart-define=KIDCOST_CRASH_REPORTING_ENABLED=false
```

Dla bety ustawiamy `KIDCOST_RELEASE_CHANNEL=beta`, podbijamy `KIDCOST_BUILD_NAME` i `KIDCOST_BUILD_NUMBER`, a `KIDCOST_ANALYTICS_ENABLED=true` oraz `KIDCOST_CRASH_REPORTING_ENABLED=true` dopiero wtedy, gdy build ma komplet konfiguracji Firebase dla Androida i iOS.

Eventy MVP:

- `signup_started`
- `signup_completed`
- `family_created`
- `child_added`
- `expense_created`
- `receipt_attached`
- `balance_viewed`
- `report_viewed`

Parametry eventow musza przechodzic przez allowliste w aplikacji. Nie wysylamy e-maili, imion dzieci, opisow kosztow, nazw plikow, pelnych kwot ani innych danych rodzinnych. Dozwolone sa tylko techniczne i agregowalne wartosci typu `release_channel`, `build_name`, `build_number`, `is_demo`, `screen`, `category_id`, `status`, `has_attachment`, `content_type`, `invitation_skipped`.

Crashlytics/analytics beta wymaga przed wyslaniem builda:

- projektu Firebase dla bety,
- Android `google-services.json` dodanego do lokalnego/CI secret setup, nie jako sekret w repo,
- iOS `GoogleService-Info.plist` dodanego do lokalnego/CI secret setup, nie jako sekret w repo,
- SDK Analytics/Crashlytics podlaczonego do mobilnej aplikacji,
- testowego crasha widocznego w panelu Crashlytics,
- potwierdzenia, ze eventy MVP pojawiaja sie bez PII i pelnych kwot.

### Smoke test Android

- [ ] clean install builda beta na emulatorze albo urzadzeniu,
- [ ] start aplikacji bez crasha,
- [ ] rejestracja testowego konta,
- [ ] utworzenie rodziny i dodanie dziecka,
- [ ] dodanie kosztu bez zalacznika,
- [ ] dodanie kosztu z zalacznikiem paragon/PDF,
- [ ] wejscie w Start i Raporty,
- [ ] wylogowanie i ponowne logowanie,
- [ ] potwierdzenie eventow MVP w analytics bez PII,
- [ ] potwierdzenie test crasha w Crashlytics.

### Smoke test iOS

- [ ] clean install builda beta przez TestFlight albo lokalny archive,
- [ ] start aplikacji bez crasha,
- [ ] rejestracja testowego konta,
- [ ] utworzenie rodziny i dodanie dziecka,
- [ ] dodanie kosztu bez zalacznika,
- [ ] dodanie kosztu z zalacznikiem paragon/PDF,
- [ ] wejscie w Start i Raporty,
- [ ] wylogowanie i ponowne logowanie,
- [ ] potwierdzenie eventow MVP w analytics bez PII,
- [ ] potwierdzenie test crasha w Crashlytics.

### Debug

- [ ] aplikacja uruchamia sie lokalnie na Android emulator,
- [ ] aplikacja uruchamia sie lokalnie na iOS Simulator,
- [ ] auth wskazuje na lokalny/dev Supabase,
- [ ] brak sekretow w logach,
- [ ] mozna utworzyc konto testowe i dodac koszt.

### Profile / beta smoke

- [ ] build korzysta z projektu Supabase beta/prod,
- [ ] RLS i prywatny Storage sa wlaczone,
- [ ] `KIDCOST_RELEASE_CHANNEL=beta`, version/build sa podbite,
- [ ] Crashlytics/analytics wskazuja na projekt beta,
- [ ] eventy MVP nie zawieraja danych osobowych ani pelnych kwot,
- [ ] test crash jest widoczny w Crashlytics,
- [ ] feature flags nie wlaczaja platnosci ani niegotowych eksportow,
- [ ] znane ograniczenia sa widoczne w notatce dla testerow.

### Release

- [ ] Android AAB podpisany release key,
- [ ] iOS archive podpisany profilem dystrybucyjnym,
- [ ] version name / marketing version ustawione,
- [ ] build number / version code zwiekszone,
- [ ] `KIDCOST_RELEASE_CHANNEL=public`, version/build sa podbite,
- [ ] analytics i crash reporting sa wlaczone tylko z poprawna konfiguracja Firebase,
- [ ] privacy/support URL dzialaja publicznie,
- [ ] testowe konto review/tester ma instrukcje logowania,
- [ ] nie ma `.env`, service role key, keystore, provisioning profiles ani certyfikatow w Git.

## Publikacja tresci

Przed pierwszym wyslaniem do TestFlight i Google Play Internal Testing tresci z `docs/web/*.md` nalezy opublikowac pod wskazanymi URL albo skopiowac 1:1 do statycznych stron pod domena `kidcost.app`.

Najprostszy wariant publikacji dla issue #35:

1. Wrzuc `docs/web/site/` jako root statycznego hostingu.
2. Skieruj `kidcost.app` na hosting.
3. Sprawdz publicznie:
   - `https://kidcost.app/privacy/`
   - `https://kidcost.app/support/`
   - `https://kidcost.app/terms/`
   - `https://kidcost.app/app/`
4. Uzyj `https://kidcost.app/privacy/` jako Privacy Policy URL w Google Play i App Store Connect.
5. Uzyj `https://kidcost.app/support/` jako Support URL w App Store Connect i jako kontakt pomocniczy w Play Console.

## Feedback beta i znane ograniczenia

Przed udostepnieniem builda testerom przygotowujemy:

- jasny kanal feedbacku przez `support@kidcost.app`,
- krotki szablon raportu bledu lub sugestii,
- liste znanych ograniczen bety,
- zasady triage rozdzielajace blocker bety od tematow V1.

Operacyjny opis procesu jest zapisany w `docs/BETA_FEEDBACK.md`.

## Sekrety i pliki, ktorych nie commitujemy

Nie commitujemy:

- `.env`, `.env.local`, `.env.production`,
- Supabase service role key,
- Firebase service account JSON,
- Android keystore i hasla do keystore,
- Apple certificates, provisioning profiles i private keys,
- App Store Connect API keys,
- Google Play service account JSON,
- lokalnych plikow konfiguracyjnych Xcode/Android Studio zawierajacych konta.

Do repo mozna dodac tylko przyklady bez sekretow, np. `.env.example`, kiedy aplikacja mobilna faktycznie powstanie.

## Blokady day-3 release

Blokery, ktore moga zatrzymac Google Play Internal Testing albo TestFlight:

- brak aktywnego Apple Developer Program albo Google Play Console,
- package name albo bundle id zajete lub niespojnie skonfigurowane,
- brak podpisywania release Android/iOS,
- brak publicznego privacy policy URL,
- brak projektu Supabase beta/prod z RLS i prywatnym Storage,
- service role key albo signing secret przypadkowo trafia do repo/logow,
- aplikacja wymaga logowania, ale nie ma instrukcji lub konta testowego dla review/testerow,
- upload zalacznikow dziala publicznie albo bez limitow,
- crash przy pierwszym uruchomieniu na czystym koncie,
- brak zgody co do danych zbieranych przez analytics/crash reporting.

Ryzyka nieblokujace day-3 demo, ale blokujace publiczny release:

- brak finalnych screenshotow,
- robocza ikona albo splash,
- niepelna lokalizacja store listingu,
- brak pelnego procesu supportu po publikacji,
- brak publicznej checklisty znanych ograniczen.

## Zrodla kontrolne

Stan do weryfikacji procesu na 2026-06-24:

- Apple TestFlight: https://developer.apple.com/testflight/
- Apple internal testers: https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/
- Apple TestFlight overview: https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/
- Google Play testing tracks: https://support.google.com/googleplay/android-developer/answer/9845334
- Google Play app review readiness and privacy policy: https://support.google.com/googleplay/android-developer/answer/9859455

## Weryfikacja przed wysłaniem do sklepów

- [ ] pliki `docs/web/privacy-policy.md`, `docs/web/support.md`, `docs/web/terms-of-service.md`, `docs/web/app-description.md` istnieją i są kompletne
- [ ] linki w opisach metadanych wskazują docelowe URL `https://kidcost.app/privacy`, `https://kidcost.app/support`, `https://kidcost.app/terms`
- [ ] treść jasno wyjaśnia, że KidCost pomaga dokumentować koszty i statusy, ale nie udziela porad prawnych
- [ ] treść jasno wyjaśnia, kto widzi dane rodziny i jakie dane są zbierane
- [ ] treść nie obiecuje pełnego end-to-end encryption, jeżeli nie jest wdrożone
- [ ] feedback beta ma gotowy kanal, szablon i liste znanych ograniczen zgodnie z `docs/BETA_FEEDBACK.md`
- [ ] Android package name to `pl.kidcost.app`
- [ ] iOS bundle id to `pl.kidcost.app`
- [ ] pierwszy release uzywa projektu Supabase beta/prod, nie dev
- [ ] internal testing i TestFlight sa traktowane jako beta, nie publiczna publikacja
- [ ] blokery day-3 release sa sprawdzone przed wyslaniem builda
