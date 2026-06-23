# KidCost - accessibility baseline dla MVP

Data: 2026-06-24
Powiazane issue: #73

Ten dokument ustala minimalny baseline accessibility dla MVP i pierwszej bety KidCost. Celem nie jest formalna certyfikacja WCAG, tylko ograniczenie bledow w widokach, ktore pokazuja kwoty, statusy, zalaczniki i akcje wplywajace na wspolny ledger rodziny.

## Zasady ogolne

- Accessibility traktujemy jako warunek zaufania, nie jako polish "na koniec".
- Krytyczne informacje nie moga polegac tylko na kolorze, malej typografii ani ukrytej hierarchii wizualnej.
- Kazdy flow musi pozostac uzywalny przy wiekszym tekscie, czytniku ekranu i mniej precyzyjnym dotyku.
- W MVP opisujemy i testujemy baseline, ale nie skladamy publicznych obietnic o formalnej zgodnosci.

## Zakres ekranow

Baseline obejmuje:

- onboarding i family setup,
- add expense z zalacznikiem paragonu,
- dashboard z podsumowaniem salda,
- expense list i expense detail,
- akcje statusu i dispute,
- podglad raportu miesiecznego,
- empty, loading, error i offline states.

## Minimalne wymagania

### 1. Typografia i skalowanie tekstu

- Layouty musza pozostac czytelne przy systemowym font scaling co najmniej do 200%.
- Krytyczne wartosci, przyciski zapisania i statusy nie moga byc uciete ani nachodzic na siebie przy duzym tekscie.
- Kwota, status i okres salda maja miec pierwszenstwo nad copy pomocniczym.
- Dlugie opisy powinny zawijac sie do wielu linii zamiast wymuszac fixed-height card.

### 2. Tap targets i gesty

- Primary controls maja miec co najmniej 44 pt na iOS lub 48 dp na Androidzie.
- Ikony zalacznika, menu statusu i akcje draft/submit musza miec osobny obszar dotyku, nie tylko ciasna ikone.
- Krytyczna akcja nie moze wymagac drag gesture bez alternatywy tap/button.
- Obok siebie nie ustawiamy malych akcji finansowych bez bezpiecznego odstepu.

### 3. Kolor i rozroznianie statusow

- Statusy i kategorie musza byc rozpoznawalne bez koloru samego w sobie.
- Kazdy status ma miec tekstowa etykiete plus dodatkowy sygnal: ikonke, obrys, pattern albo shape.
- Kolor ostrzezenia lub bledu nie moze byc jedynym sygnalem, ze wpis nie zostal zapisany albo jest sporny.
- Wykresy i summary chips potrzebuja redundantnej legendy albo podpisu.

### 4. Czytniki ekranu i semantyka

- VoiceOver/TalkBack musza czytac kwote, kto zaplacil, status, stan zalacznika i skutki akcji.
- Interaktywne elementy listy musza miec stabilna kolejnosc fokusu: naglowek, kluczowe dane, status, akcje.
- Dekoracyjne ikony nie powinny dublowac etykiet glosowych.
- Elementy typu "udostepni drugiemu rodzicowi" albo "tylko draft prywatny" musza byc jawnie opisane w semantyce.

### 5. Copy i stany bledu

- Komunikaty bledow maja mowic, co poszlo nie tak i co mozna zrobic dalej.
- Draft, submit, notify i dispute musza miec czytelne rozroznienie jezykowe.
- Bledu walidacji nie chowamy w samym kolorze ramki pola.
- Empty states i offline states maja zawierac jedna glowna akcje oraz jednozdaniowy opis.

## Akceptacja per kluczowy flow

### Add expense

- Formularz pozostaje uzywalny przy duzym tekscie.
- Zalacznik ma widoczny status: dodany, brak, upload failed, private draft.
- Przycisk zapisu oraz informacja o skutkach zapisu sa czytelne bez przewijania poziomego.

### Dashboard i saldo

- Kwota salda, okres i zakres danych sa widoczne bez kolorystycznego kodu.
- Czytnik ekranu odczytuje kto komu powinien oddac oraz jaki zakres kosztow jest wliczony.
- Statusy `draft`, `pending`, `accepted`, `disputed`, `settled` nie zlewaja sie wizualnie.

### Expense detail i dispute

- Powod sporu, zalaczniki i historia zmian sa dostepne w logicznej kolejnosci fokusu.
- Nie ma akcji o niejasnym skutku typu sam symbol bez etykiety.
- Wysylka sporu albo zmiana statusu nie moze zalezec od malego chipa bez pelnego labela.

### Report preview

- Podglad raportu pokazuje zakres dat, dziecko i status eksportu w sposob czytelny przy duzym tekscie.
- Sekcje `plan`, `actual` i `zalozenia` sa rozdzielone nie tylko kolorem.

## Wskazowki implementacyjne dla Flutter MVP

- Preferowac layouty elastyczne zamiast stalej wysokosci kart i fixed pixel stacks.
- Testowac semantics labels dla kwoty, platnika, statusu i attachment state na widgetach krytycznych.
- Projektowac komponenty statusu jako `label + icon/shape`, nie jako sam kolorowy pill.
- Trzymac primary action w komponencie, ktory da sie obslugiwac z klawiatury ekranowej i czytnika bez niestandardowego gestu.

## QA i regresja

Scenariusze regresyjne dla tego baseline sa zapisane w `docs/TEST_SCENARIOS.md`:

- TC-045 - duzy tekst i brak clippingu w krytycznych flow,
- TC-046 - VoiceOver/TalkBack labels dla kwot, statusow i zalacznikow,
- TC-047 - statusy i kategorie rozroznialne bez koloru,
- TC-048 - target size, focus order i akcje w widokach finansowych.

## Poza zakresem

- Formalny audyt WCAG 2.2,
- osobny panel ustawien accessibility,
- deklaracje marketingowe o zgodnosci accessibility,
- redesign calego branding layer.
