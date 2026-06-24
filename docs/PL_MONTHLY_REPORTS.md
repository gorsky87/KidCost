# KidCost - PL monthly child-cost report

Data: 2026-06-24

## Scope

Ten dokument zamyka zakres dla issue #56 i #62 przez jeden wspolny surface produktowy:

- `Miesieczny kosztorys dziecka` jako raport i ekran roboczy dla rynku PL,
- porownanie `plan` kontra `rzeczywiste koszty`,
- opcjonalna sekcja `Zalozenia i swiadczenia`,
- eksport organizacyjny bez obietnicy porady prawnej, podatkowej albo wyliczenia alimentow.

To nie jest osobny kalkulator alimentow. To uporzadkowany raport miesieczny oparty o dane KidCost i jawne notatki rodzica.

## Problem, ktory rozwiazujemy

Polscy rodzice czesto potrzebuja dwoch rzeczy naraz:

- zobaczyc miesieczny koszt utrzymania dziecka w kategoriach znanych z rozmow rodzinnych, mediacyjnych i kancelaryjnych,
- dopisac kontekst typu `800+`, `Dobry Start`, ulga podatkowa albo opieka naprzemienna bez mieszania tego z faktycznymi wydatkami.

Sam ledger kosztow nie odpowiada na pytanie `ile kosztuje miesiac` i `jakie zalozenia byly brane pod uwage`. Z kolei aplikacja nie moze udawac kalkulatora alimentow ani doradcy prawnego.

## Zasady produktu

- Fakty finansowe i zalozenia uzytkownika sa rozdzielone wizualnie i logicznie.
- Saldo, zwroty i reimbursement calculations nie zmieniaja sie od wypelnienia tej sekcji.
- Wszystkie pola dotycza jednego dziecka i jednego miesiaca.
- Funkcja jest opcjonalna i moze zaczac jako `display/export only`.
- Copy ma byc spokojne i neutralne: raport porzadkuje dane, nie interpretuje prawa.

## MVP

Pierwsza wersja zawiera:

- wybor dziecka i miesiaca,
- plan miesieczny per kategoria,
- rzeczywiste koszty z tego samego miesiaca,
- roznice plan vs actual,
- opcjonalna sekcje `Zalozenia i swiadczenia`,
- eksport tekstowy/CSV/PDF z disclaimerem,
- analityke agregatowa bez tresci wpisanych notatek.

Pierwsza implementacja nie musi zmieniac modelu rozliczen i nie musi liczyc zadnych rekomendacji.

## Kategorie planu miesiecznego

Minimalny zestaw kategorii dla PL:

- edukacja i opieka,
- zajecia dodatkowe,
- wyzywienie,
- zdrowie,
- ubrania i obuwie,
- dojazdy,
- wakacje i ferie,
- rozrywka,
- udzial w kosztach mieszkaniowych.

Zasady:

- plan jest wpisywany jako miesieczna kwota na kategorie,
- `rzeczywiste koszty` sa agregowane z istniejacych wydatkow KidCost,
- roznica moze byc dodatnia albo ujemna, ale nie zmienia salda,
- brak danych w planie nie blokuje generacji raportu.

## Sekcja "Zalozenia i swiadczenia"

Sekcja jest widoczna tylko jako kontekst uzytkownika i nie wplywa na obliczenia.

### Pola MVP

- `800+`: `parent_a`, `parent_b`, `split`, `unknown`
- `Dobry Start`: `yes`, `no`, `unknown`
- `Ulga na dziecko / PIT`: krotka nota faktograficzna
- `Opieka naprzemienna`: krotka nota faktograficzna
- `Dodatkowe zalozenie`: krotka notatka uzytkownika

### Reguly UX

- Kazde pole ma pomocniczy tekst: `To jest kontekst wpisany przez Ciebie. Nie wplywa na saldo ani zwroty.`
- Sekcja jest domyslnie zwinieta, zeby nie przytlaczala glownego raportu.
- Free-text ma limit dlugosci i powinien byc opisany jako `notatka organizacyjna`, nie `uzasadnienie prawne`.
- W eksporcie sekcja jest oddzielona od rzeczywistych kosztow naglowkiem `Zalozenia i swiadczenia (wpis uzytkownika)`.

## Struktura ekranu i raportu

Kolejnosc sekcji:

1. Naglowek: dziecko, miesiac, zakres danych.
2. Podsumowanie: plan laczny, rzeczywiste koszty laczne, roznica.
3. Kategorie: tabela plan / actual / roznica.
4. Ledger summary: liczba kosztow, statusy, ewentualne rozbicie na rodzicow.
5. `Zalozenia i swiadczenia`: sekcja opcjonalna.
6. Disclaimer i data eksportu.

## Copy gotowe do pierwszej wersji

### Polski

- Nazwa ekranu: `Miesieczny kosztorys dziecka`
- Opis: `Porownaj plan miesiaca z rzeczywistymi kosztami zapisanymi w KidCost.`
- Label sekcji: `Zalozenia i swiadczenia`
- Help text: `Ta sekcja porzadkuje notatki do raportu. Nie zmienia salda, zwrotow ani rozliczen.`
- Disclaimer: `KidCost porzadkuje dane finansowe i notatki uzytkownika. Nie udziela porad prawnych ani podatkowych i nie wylicza naleznych alimentow.`

### English fallback

- Screen name: `Monthly child-cost summary`
- Description: `Compare your monthly plan with actual child expenses saved in KidCost.`
- Section label: `Assumptions and benefits`
- Help text: `This section stores user-entered context only. It does not change balances or reimbursements.`
- Disclaimer: `KidCost organizes financial records and user notes. It does not provide legal or tax advice and does not calculate child support obligations.`

## Eksport

Eksport MVP powinien:

- jasno pokazywac miesiac i dziecko,
- oddzielac `rzeczywiste koszty` od `planu` i od `zalozen`,
- zachowywac neutralny ton,
- zawierac disclaimer w stopce albo podsumowaniu,
- nie sugerowac, ze dokument ma wartosc opinii prawnej albo podatkowej.

Warianty eksportu:

- tekst do skopiowania,
- CSV z kategoriami i sumami,
- prosty PDF, gdy issue #30 dojrzeje do implementacji.

## Dane i kontrakty

Logika obliczen:

- plan miesieczny jest osobnym bytem raportowym,
- zalozenia i swiadczenia sa metadanymi raportu,
- zadne z tych pol nie modyfikuje expense ledger ani split rules,
- saldo 50/50 lub przyszle custom split pozostaja liczone z kosztow i statusow, nie z notatek raportowych.

Minimalny kontrakt API/UI powinien rozroznic:

- `actual_expense_totals`,
- `planned_category_totals`,
- `report_assumptions`,
- `export_disclaimer`,
- `analytics_flags`.

## Analytics

Mozemy mierzyc tylko sygnaly agregatowe:

- czy kosztorys zostal uruchomiony,
- czy wpisano plan miesieczny,
- czy otwarto sekcje `Zalozenia i swiadczenia`,
- czy wybrano ktoras z opcji `800+` albo `Dobry Start`,
- czy wykonano eksport.

Nie zapisujemy do analytics:

- tresci pola `Dodatkowe zalozenie`,
- notatek o PIT,
- notatek o opiece naprzemiennej,
- nazw dziecka ani tresci kosztow z tego formularza jako payloadu eventu.

## Powiazania z innymi issue

- Issue #23: ten dokument rozszerza miesieczny raport o czytelny kosztorys i jezyk bez ksiegowosci.
- Issue #30: backend/export korzysta z kontraktu opisanego w `docs/MONTHLY_REPORT_API.md`.
- Issue #56: adresowane przez kategorie planu, porownanie plan vs actual i eksport organizacyjny.
- Issue #62: adresowane przez sekcje `Zalozenia i swiadczenia`, disclaimer i zasade `display only`.

## Non-goals

- wyliczanie alimentow,
- rekomendowanie procentu udzialu rodzicow,
- automatyczna interpretacja 800+, PIT albo Dobry Start,
- zmiana salda na podstawie swiadczen,
- porada prawna, podatkowa albo ksiegowa.
