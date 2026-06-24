# KidCost UX MVP - flow day-3 demo

## Cel dokumentu

Ten dokument opisuje minimalny flow MVP, ktory ma byc zrozumialy bez
dodatkowego tlumaczenia. Demo ma doprowadzic uzytkownika do jednego momentu:

> Wiem, kto komu ile oddaje.

Flow miesci sie w 5 glownych ekranach:

1. Logowanie.
2. Start rodziny.
3. Dashboard.
4. Dodanie kosztu.
5. Lista kosztow.

Raporty i kalendarz moga byc widoczne w nawigacji, ale nie sa konieczne do
day-3 demo i nie powinny rozpraszac pierwszego przejscia.

## Zasady UX

- Uzytkownik uczy sie przez dzialanie, nie przez instrukcje.
- Pierwsza akcja po onboardingu to dodanie kosztu.
- Saldo zawsze jest zdaniem kierunkowym, np. `Drugi rodzic oddaje Tobie 30 zl`.
- Formularz kosztu ma tylko jedna nieoczywista decyzje: kto zaplacil.
- Jezyk jest spokojny i faktograficzny: `sporne`, `do rozliczenia`,
  `drugi rodzic`, bez oskarzen.
- Empty state prowadzi do nastepnej akcji, a nie tlumaczy calego produktu.

## Flow 1: pierwsze uruchomienie i logowanie

### Ekran

`Logowanie`

### Cel uzytkownika

Wejsc do aplikacji bez zastanawiania sie nad konfiguracja rodziny.

### Low-fi wireframe

```text
KidCost
Porzadek w kosztach dziecka

[ Email                         ]
[ Haslo                         ]

[ Zaloguj ]

Nie masz konta? Utworz konto

Tryb demo, jesli backend nie jest skonfigurowany
```

### CTA

- Primary: `Zaloguj`
- Secondary: `Utworz konto`

### Stany

- Empty: puste pola, primary CTA widoczne.
- Loading: primary CTA z loaderem i blokada ponownego tapniecia.
- Error: komunikat pod formularzem, np. `Nie udalo sie zalogowac. Sprawdz email i haslo.`
- Success: przejscie do startu rodziny albo dashboardu.

### Decyzje

- Nie pokazujemy dlugiego opisu funkcji.
- Nie prosimy o zaproszenie drugiego rodzica przed pierwszym kosztem.

## Flow 2: start rodziny po zalogowaniu

### Ekran

`Start rodziny`

### Cel uzytkownika

Utworzyc minimalny kontekst: rodzina i dziecko.

### Low-fi wireframe

```text
Jak zaczynamy?

[ Zakladam rodzine ]
[ Mam kod zaproszenia ]

Nazwij rodzine
[ Rodzina Kowalskich ]

Dodaj dziecko
[ Imie dziecka ]

Zapros rodzica
[ Email drugiego rodzica ]
[ Wygeneruj kod ]

[ Pomin zaproszenie ]
```

### CTA

- Primary: `Zakladam rodzine`
- Primary step CTA: `Dalej`
- Secondary: `Pomin zaproszenie`

### Stany

- Empty: pola z przykladami, bez dlugiej instrukcji.
- Loading: generowanie kodu zaproszenia.
- Error: walidacja imienia dziecka i emaila.
- Success: przejscie do dashboardu.

### Decyzje

- Zaproszenie drugiego rodzica jest opcjonalne.
- Tryb solo jest akceptowany, bo pozwala dojsc do wartosci bez blokady.

## Flow 3: dashboard bez kosztow

### Ekran

`Dashboard`

### Cel uzytkownika

Zrozumiec, co zrobic jako pierwsze.

### Low-fi wireframe

```text
Podsumowanie miesiaca
Rodzina: ...
Dziecko: ...

[ Dodaj koszt ]
[ Raport miesiaca ]

Kto komu oddaje
Brak kosztow do wyrownania

Brak kosztow w tym miesiacu
Dodaj pierwszy koszt, a od razu zobaczysz kto ile zaplacil i kto komu oddaje.
[ Dodaj pierwszy koszt ]

Najblizsza opieka
Dodaj dni opieki w zakladce Opieka...
```

### CTA

- Primary: `Dodaj koszt`
- Empty-state CTA: `Dodaj pierwszy koszt`
- Secondary: `Raport miesiaca`

### Stany

- Empty: saldo pokazuje `Brak kosztow do wyrownania`, a karta empty prowadzi do kosztu.
- Loading: tylko jezeli dane beda pobierane z backendu; skeleton lub prosty loader na kartach.
- Error: karta `Nie udalo sie pobrac kosztow`, z CTA `Sprobuj ponownie`.
- Success: widoczne saldo, suma miesiaca i ostatnie koszty.

### Decyzje

- Empty dashboard nie opisuje wszystkich funkcji aplikacji.
- Pierwszy ekran po konfiguracji ma prowadzic do jednego dzialania: dodania kosztu.
- `Raport miesiaca` jest secondary, bo raport bez kosztow nie daje pierwszego efektu aha.

## Flow 4: dodanie pierwszego kosztu

### Ekran

`Dodaj koszt`

### Cel uzytkownika

Dodac koszt w mniej niz minute i bez zbednych decyzji.

### Low-fi wireframe

```text
Nowy koszt

[ Kwota             0,00 ]
[ Data kosztu       RRRR-MM-DD ]

Dziecko
Antek

[ Kategoria         Jedzenie v ]
[ Kto zaplacil      parent@example.com v ]
[ Opis lub nazwa kosztu        ]

[ Dodaj paragon lub PDF ]

[ Zapisz koszt ]
```

### CTA

- Primary: `Zapisz koszt`
- Secondary: `Dodaj paragon lub PDF`

### Stany

- Empty: domyslna kategoria, domyslny placacy, puste kwota/data/opis.
- Loading: `Zapisz koszt` z loaderem, pola zablokowane.
- Error: walidacja przy polu, np. `Podaj kwote wieksza od 0.`
- Attachment error: koszt zapisany, ale zalacznik ma status bledu.
- Success: snackbar `Koszt zapisany.` i wyczyszczenie formularza.

### Jedyna nieoczywista decyzja

`Kto zaplacil`

Pozostale decyzje powinny byc oczywiste:

- kwota,
- data,
- kategoria,
- opcjonalny opis,
- opcjonalny zalacznik.

### Decyzje

- Nie wymagamy opisu, bo kategoria moze byc tytulem kosztu.
- Zalacznik nie blokuje zapisu kosztu.
- Status kosztu po dodaniu to `Do rozliczenia`.

## Flow 5: powrot do dashboardu i zobaczenie salda

### Ekran

`Dashboard po dodaniu kosztu`

### Cel uzytkownika

Zobaczyc wartosc aplikacji natychmiast po pierwszym koszcie.

### Low-fi wireframe

```text
Kto komu oddaje
Drugi rodzic oddaje Tobie 6,25 zl
Liczymy prosty podzial 50/50.

Wydatki w tym miesiacu
12,50 zl
2026-06

Ty zaplaciles
12,50 zl

Drugi rodzic zaplacil
0,00 zl

Ostatnie koszty
Obiad
2026-06-24 • Jedzenie • parent@example.com
12,50 zl
```

### CTA

- Primary zostaje `Dodaj koszt`.
- Secondary zostaje `Raport miesiaca`.

### Stany

- Success: saldo jako zdanie kierunkowe.
- Edge case zero: `Jestescie rozliczeni na zero`.
- Only co-parent paid: `Ty oddajesz drugiemu rodzicowi 40,00 zl`.

### Decyzje

- Nie pokazujemy samej liczby dodatniej/ujemnej.
- Nie uzywamy jezyka ksiegowego typu `naleznosc`, `saldo debetowe`.
- W demo mozna powiedziec `drugi rodzic`, pozniej personalizacja imion.

## Flow 5b: wejscie w liste kosztow

### Ekran

`Koszty`

### Cel uzytkownika

Sprawdzic, skad wzielo sie saldo.

### Low-fi wireframe

```text
Filtry
[ Pokaz filtry i sortowanie v ] [ Wyczysc ]

Obiad
Jedzenie • Antek • 2026-06-24 • Zaplacil: parent@example.com • Status: Do rozliczenia
12,50 zl
```

Po tapnieciu kosztu:

```text
Szczegoly kosztu

Nazwa       Obiad
Kwota       12,50 zl
Kategoria   Jedzenie
Dziecko     Antek
Placacy     parent@example.com
Data        2026-06-24
Status      Do rozliczenia

Brak zalacznika

[ Edytuj koszt ]
```

### CTA

- Filter panel: `Pokaz filtry i sortowanie`
- Clear filters: `Wyczysc`
- Details: `Edytuj koszt`, tylko gdy status pozwala.

### Stany

- Empty: `Brak kosztow`, z opisem ze lista pokaze koszty, statusy i zalaczniki.
- Loading: `Ladowanie kosztow`.
- Error: `Nie udalo sie pobrac kosztow`.
- Filter empty: `Brak kosztow dla filtrow`, z CTA `Wyczysc filtry`.
- Success: karta kosztu pokazuje kwote, status i najwazniejsze pola bez wejscia w szczegoly.

### Decyzje

- Lista kosztow jest wyjasnieniem dashboardu, nie osobnym centrum dowodzenia.
- Filtry sa zwijane, zeby pierwsze koszty byly widoczne bez scrollowania.
- Status kosztu jest widoczny bez wejscia w szczegoly.

## Bottom navigation

### Decyzja

Bottom navigation zostaje najlepszym wyborem dla MVP.

### Uzasadnienie

- Uzytkownik widzi glowne obszary bez uczenia sie menu.
- Day-3 demo wymaga szybkiego przejscia: `Start -> Dodaj -> Start -> Koszty`.
- Mobile-first produkt naturalnie pasuje do stalej dolnej nawigacji.
- Zakladki sa stabilne dla przyszlych obszarow: raporty i opieka.

### Zalecany porzadek MVP

1. `Start`
2. `Koszty`
3. `Dodaj`
4. `Opieka`
5. `Raporty`
6. `Rodzina`
7. `Ustawienia`

### Ryzyko

Siedem pozycji to za duzo na dluzszy okres. Dla day-3 demo jest akceptowalne,
bo pokazuje zakres produktu, ale po pierwszych testach warto rozwazyc:

- `Dodaj` jako floating action button,
- `Rodzina` i `Ustawienia` pod jednym profile/menu,
- `Raporty` jako wejscie z dashboardu i listy kosztow, jesli dolna belka bedzie zbyt ciasna.

## Lista wymaganych stanow

| Obszar | Empty | Loading | Error | Success |
| --- | --- | --- | --- | --- |
| Logowanie | puste pola | loader na CTA | blad logowania | przejscie dalej |
| Onboarding | brak rodziny/dziecka | generowanie kodu | walidacja emaila/imienia | dashboard |
| Dashboard | brak kosztow | loader kart | blad pobrania danych | saldo i ostatnie koszty |
| Dodaj koszt | puste pola | zapis kosztu | walidacja kwoty/daty | snackbar i nowy koszt |
| Lista kosztow | brak kosztow | ladowanie kosztow | blad listy | lista + szczegoly |
| Raporty | brak kosztow w miesiacu | pozniej backend | blad eksportu | raport + CSV |
| Opieka | brak dni opieki | pozniej backend | blad zapisu | miesiac z oznaczeniami |

## Propozycje tresci CTA

| Moment | CTA |
| --- | --- |
| Logowanie | `Zaloguj` |
| Rejestracja | `Utworz konto` |
| Start rodziny | `Zakladam rodzine` |
| Pomijanie zaproszenia | `Pomin zaproszenie` |
| Dashboard empty | `Dodaj pierwszy koszt` |
| Dashboard regular | `Dodaj koszt` |
| Formularz kosztu | `Zapisz koszt` |
| Zalacznik | `Dodaj paragon lub PDF` |
| Lista filtrow | `Pokaz filtry i sortowanie` |
| Czyszczenie filtrow | `Wyczysc filtry` |
| Raport | `CSV: kidcost-report-YYYY-MM.csv` |
| Opieka | `Zapisz opieke` |

## Kryteria gotowosci day-3 demo

- Nowy uzytkownik moze wejsc do aplikacji i dodac koszt bez pytania, co dalej.
- Empty dashboard ma widoczne `Dodaj koszt`.
- Po pierwszym koszcie dashboard pokazuje kierunkowe saldo.
- Lista kosztow wyjasnia saldo i pokazuje status.
- Glowne flow miesci sie w 5 ekranach: logowanie, start rodziny, dashboard,
  dodaj koszt, lista kosztow.
- Bottom navigation wspiera demo, ale ma zapisane ryzyko nadmiaru pozycji.

## Decyzje poza zakresem tego dokumentu

- Pelny system mediacji.
- Panel prawnika lub mediatora.
- Zaawansowane spory z komentarzami.
- Wzorce wakacyjne w kalendarzu opieki.
- Finalny brand, logo i system wizualny.
