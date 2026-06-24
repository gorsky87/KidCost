# KidCost UX - raporty, saldo i jezyk finansowy

## Cel

Rodzic ma po kilku sekundach zrozumiec sytuacje finansowa bez znajomosci
ksiegowosci. Najwazniejsze zdanie brzmi zawsze kierunkowo: kto komu ile oddaje.

## Zasady copy

- Pokazujemy kierunek platnosci: `Drugi rodzic oddaje Tobie 30,00 zl`.
- Nie pokazujemy samotnych znakow `+` i `-`.
- Uzywamy slow codziennych: `zaplacone`, `udzial`, `roznica`,
  `do wyrownania`.
- Unikamy slow: `debet`, `saldo winien`, `konto rozrachunkowe`, `naleznosc`.
- Przy kosztach spornych uzywamy tonu z UX statusow:
  `Wymaga wyjasnienia`, nie `odrzucone`.

## Dashboard salda

Hierarchia:

1. `Kto komu oddaje` - jedno zdanie kierunkowe.
2. `Wydatki w tym miesiacu` - suma wszystkich kosztow z widocznym miesiacem.
3. `Ty zaplaciles`.
4. `Drugi rodzic zaplacil`.
5. `Ostatnie koszty`.

Low-fi:

```text
Podsumowanie miesiaca

[ Dodaj koszt ]   [ Raport miesiaca ]

Kto komu oddaje
Drugi rodzic oddaje Tobie 30,00 zl
Liczymy prosty podzial 50/50.

Wydatki w tym miesiacu
180,00 zl
2026-06

Ty zaplaciles
120,00 zl

Drugi rodzic zaplacil
60,00 zl
```

## Raport miesieczny

Raport zaczyna sie od odpowiedzi, a dopiero potem pokazuje rozbicie.

Hierarchia:

1. `Do wyrownania` - to samo zdanie kierunkowe co na dashboardzie.
2. `Zaplacone razem`.
3. `Zaplaciles Ty`.
4. `Zaplacil drugi rodzic`.
5. `Twoj udzial`.
6. `Roznica`.
7. Statusy: `Wymaga wyjasnienia`, `Do akceptacji`, `Rozliczone`.
8. Rozbicia: rodzice, dzieci, kategorie.
9. Lista kosztow w raporcie.
10. Eksport CSV/PDF.

Low-fi:

```text
Raport miesieczny
[ 2026-06 v ]

Do wyrownania                         Drugi rodzic oddaje Tobie 30,00 zl
Zaplacone razem                       180,00 zl
Zaplaciles Ty                         120,00 zl
Zaplacil drugi rodzic                 60,00 zl
Twoj udzial                           90,00 zl
Roznica                               Zaplaciles o 30,00 zl wiecej niz Twoj udzial.
Wymaga wyjasnienia                    60,00 zl
Do akceptacji                         120,00 zl
Rozliczone                            0,00 zl

Zaplacone przez rodzicow
parent@example.com                    120,00 zl
Drugi rodzic                          60,00 zl

Koszty dzieci
Antek                                 180,00 zl

Kategorie kosztow
Jedzenie                              120,00 zl
Lekarze i leki                        60,00 zl
```

## Warianty

| Wariant | Tekst |
| --- | --- |
| Brak kosztow | `Brak kosztow do wyrownania` i empty state `Raport jest gotowy, ale nie ma jeszcze danych do pokazania.` |
| Tylko Ty placisz | `Drugi rodzic oddaje Tobie ...` |
| Tylko drugi rodzic placi | `Ty oddajesz drugiemu rodzicowi ...` |
| Po rowno | `Jestescie rozliczeni na zero` |
| Koszty sporne | Pokazujemy ich sume jako `Wymaga wyjasnienia`, ale nie zmieniamy tonu na konfrontacyjny. |
| Koszty rozliczone | Pokazujemy ich sume jako `Rozliczone`, zeby rodzic odroznil historie od rzeczy do zrobienia. |

## Gotowe teksty do aplikacji

- `Do wyrownania`
- `Zaplacone razem`
- `Zaplaciles Ty`
- `Zaplacil drugi rodzic`
- `Twoj udzial`
- `Roznica`
- `Liczymy prosty podzial 50/50.`
- `Zaplaciles o 30,00 zl wiecej niz Twoj udzial.`
- `Zaplaciles o 30,00 zl mniej niz Twoj udzial.`
- `Twoje platnosci sa rowne Twojemu udzialowi.`
- `Zaplacone przez rodzicow`
- `Koszty dzieci`
- `Kategorie kosztow`

## Beta 1

Wymagane:

- Dashboard z jednym zdaniem salda.
- Raport miesieczny z hierarchia: saldo, suma, zaplacone, udzial, roznica,
  statusy, rozbicia.
- CSV z czytelnymi statusami.
- Empty state bez dlugich instrukcji.

Pozniej:

- Wybieralne proporcje inne niz 50/50.
- Raport roczny i sadowy.
- Eksport PDF z ta sama hierarchia informacji.
- Jawna decyzja, czy koszty `Wymaga wyjasnienia` licza sie do kwoty
  `Do wyrownania`, czy sa tylko pokazane obok.
