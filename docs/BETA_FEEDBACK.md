# KidCost - feedback beta i backlog V1

Data: 2026-06-24
Powiazane issue: #72

Ten dokument opisuje lekki proces feedbacku dla TestFlight i Google Play Internal Testing oraz sposob zamiany problemow z bety na uporzadkowany backlog V1 bez duplikowania istniejacych issues.

## Cele

- dac testerom jeden prosty sposob raportowania problemow,
- ograniczyc przesylanie danych wrazliwych dzieci, kwot i pelnych paragonow,
- odroznic blocker bety od polishu i pomyslow na V1,
- utrzymac jeden backlog bez duplikatow.

## Kanaly feedbacku

### 1. Domyslny kanal dla testerow

- E-mail: `support@kidcost.app`
- Temat: `KidCost beta - [bug|feedback|privacy] - krotki opis`
- Dla bledow technicznych tester podaje tez wersje aplikacji, model telefonu i wersje systemu.

### 2. Kanal wewnetrzny

- GitHub issue albo komentarz do istniejacego issue, jezeli problem mapuje sie do juz otwartego zadania.
- Nie tworzymy nowego issue, jezeli problem jest tylko nowym przypadkiem dla istniejacego backlogu.

### 3. Eskalacja privacy/security

- Jezeli zgloszenie dotyczy wycieku danych, dostepu do obcej rodziny, zalacznikow lub telemetryki, oznaczamy je od razu jako `privacy/security`.
- Takie zgloszenie nie czeka na zwykla sesje triage.

## Szablon feedbacku dla testerow

Tester powinien wyslac tylko minimum potrzebne do odtworzenia problemu:

1. Kontekst:
   - co probowal zrobic,
   - czy dotyczy to draftu, wyslanego kosztu, raportu, logowania czy zalacznika.
2. Kroki:
   - 2-6 krokow pozwalajacych odtworzyc zachowanie.
3. Oczekiwane zachowanie:
   - co tester spodziewal sie zobaczyc.
4. Rzeczywiste zachowanie:
   - co stalo sie naprawde.
5. Wplyw:
   - blocker,
   - mylace ale da sie obejsc,
   - tylko polish lub sugestia.
6. Zalacznik:
   - screen lub screen recording bez danych dziecka, pelnych kwot i pelnych paragonow, jezeli to mozliwe.

## Czego nie prosimy wysylac

- pelnych danych dziecka,
- pelnych numerow kart i danych platnosci,
- calych paragonow, jezeli wystarczy kadr z bledem UI,
- eksportow z danymi drugiej rodziny bez wyraznej potrzeby diagnostycznej,
- notatek z sekcji `Zalozenia i swiadczenia`, jezeli problem nie dotyczy samego pola.

## Lista znanych ograniczen bety

Przed udostepnieniem linkow testowych publikujemy albo wysylamy razem z buildem te ograniczenia:

- MVP nie daje porad prawnych, podatkowych ani finansowych.
- OCR, automatyzacje AI i zaawansowane raporty sa poza zakresem tej bety.
- Nie wszystkie flow maja jeszcze produkcyjna obsluge offline i synchronizacji konfliktow.
- TestFlight / Internal Testing moga zawierac znane braki UI, copy i accessibility poza baseline MVP.
- Wersja beta moze miec ograniczona obsluge kalendarza, eksportow oraz zaawansowanych splitow kosztow.

## Reguly triage

Kazde zgloszenie dostaje jedna glowna kategorie:

- `beta-blocker` - uniemozliwia sensowny test albo grozi blednym ledgerem, utrata danych, privacy leak lub zlym saldem.
- `bug` - zachowanie jest bledne, ale istnieje obejscie lub zasieg jest ograniczony.
- `polish` - copy, layout, mikrointerakcje, brakujacy hint, niejasny stan.
- `privacy/security` - ryzyko wycieku danych, nadmiernej telemetryki, zlego dostepu lub ekspozycji zalacznikow.
- `v1-feature` - wartosciowy pomysl po becie, ale nie blocker aktualnego testu.
- `later` - temat swiadomie odlozony poza V1.

### Priorytet operacyjny

- P0: privacy leak, utrata danych, bledne saldo, brak logowania, crash blokujacy glowny flow.
- P1: krytyczny bug bez sensownego obejscia.
- P2: wazny bug z obejsciem albo brak zaufania/clarity w kluczowym flow.
- P3: polish albo temat na przyszlosc.

## Zasady backlogu V1

- Najpierw szukamy, czy istnieje juz issue o tym samym problemie albo tej samej luce produktowej.
- Jezeli issue istnieje, dopisujemy komentarz z nowym przypadkiem, screenem i decyzja triage.
- Nowe issue tworzymy tylko wtedy, gdy problem nie pasuje do zadnego otwartego zadania.
- Backlog V1 ma byc krotki: tylko tematy potwierdzone przez bete, nie ogolna liste zyczen.

## Rytm po rundzie testow

1. Zbieramy feedback przez `support@kidcost.app` i wewnetrzne notatki testowe.
2. Raz po kazdej rundzie bety robimy triage z podzialem na `beta-blocker`, `bug`, `privacy/security`, `v1-feature`, `later`.
3. Aktualizujemy istniejace issue albo tworzymy tylko brakujace.
4. Zapisujemy liste znanych ograniczen i decyzje, co wchodzi do V1.

## Powiazanie z istniejacymi dokumentami

- `docs/RELEASE.md` - checklist przed wyslaniem builda i publikacja linkow.
- `docs/web/support.md` - publiczny punkt kontaktu dla testerow.
- `docs/TEST_SCENARIOS.md` - scenariusze regresyjne dla procesu feedbacku i triage.

## QA i regresja

Scenariusze regresyjne dla tego procesu sa zapisane w `docs/TEST_SCENARIOS.md`:

- TC-049 - feedback z bety bez danych wrazliwych,
- TC-050 - lista znanych ograniczen i jasny triage przed udostepnieniem builda.
