class KidCostUserScenario {
  const KidCostUserScenario({
    required this.id,
    required this.area,
    required this.actor,
    required this.action,
    required this.timing,
    required this.expectedOutcome,
    required this.coverage,
  });

  final String id;
  final String area;
  final String actor;
  final String action;
  final String timing;
  final String expectedOutcome;
  final List<String> coverage;

  String get whoWhatWhen => '$actor | $action | $timing';
}

const kidCostScenarioAreas = [
  'Auth',
  'Onboarding',
  'Shell',
  'Dashboard',
  'Expenses',
  'Proofs',
  'Templates',
  'Plans',
  'Custody',
  'Reports',
  'Family',
  'Settings',
  'Privacy',
  'Premium',
  'Release',
];

const kidCostUserScenarios = [
  KidCostUserScenario(
    id: 'AUTH-01',
    area: 'Auth',
    actor: 'Rodzic z kontem',
    action: 'moze zalogowac sie emailem i haslem',
    timing: 'kiedy uruchamia aplikacje i podaje poprawne dane',
    expectedOutcome:
        'aplikacja otwiera shell KidCost i nie pokazuje danych przed logowaniem',
    coverage: ['widget_test: opens the KidCost shell after email sign in'],
  ),
  KidCostUserScenario(
    id: 'AUTH-02',
    area: 'Auth',
    actor: 'Nowy rodzic',
    action: 'moze utworzyc konto emailem i haslem',
    timing: 'kiedy nie ma jeszcze sesji i przechodzi w tryb rejestracji',
    expectedOutcome:
        'po rejestracji trafia do startu rodziny bez osobnego setupu technicznego',
    coverage: [
      'widget_test: registration opens the shell for a new email session',
    ],
  ),
  KidCostUserScenario(
    id: 'AUTH-03',
    area: 'Auth',
    actor: 'Nowy rodzic',
    action: 'nie moze zalozyc konta ze zbyt slabym haslem',
    timing: 'kiedy wpisuje haslo krotsze niz minimum',
    expectedOutcome:
        'aplikacja pokazuje spokojny blad walidacji i zostaje na ekranie auth',
    coverage: ['widget_test: registration validates weak passwords'],
  ),
  KidCostUserScenario(
    id: 'AUTH-04',
    area: 'Auth',
    actor: 'Zalogowany rodzic',
    action: 'moze wylogowac sie z aplikacji',
    timing: 'kiedy konczy prace w ustawieniach konta',
    expectedOutcome:
        'sesja wraca do ekranu logowania bez widocznych danych rodziny',
    coverage: ['widget_test: logout clears the user session'],
  ),
  KidCostUserScenario(
    id: 'ONB-01',
    area: 'Onboarding',
    actor: 'Rodzic zakladajacy rodzine',
    action: 'moze nazwac rodzine i dodac dziecko',
    timing: 'kiedy loguje sie po raz pierwszy',
    expectedOutcome:
        'dashboard dostaje minimalny kontekst rodziny bez blokady zaproszeniem',
    coverage: ['widget_test: signup and onboarding emit safe telemetry events'],
  ),
  KidCostUserScenario(
    id: 'ONB-02',
    area: 'Onboarding',
    actor: 'Rodzic zakladajacy rodzine',
    action: 'moze wygenerowac kod zaproszenia dla drugiego rodzica',
    timing: 'kiedy zna email drugiego rodzica podczas onboardingu',
    expectedOutcome:
        'kod powstaje bez ujawniania danych rodzinnych przed akceptacja zaproszenia',
    coverage: ['widget_test: onboarding can create an invitation code'],
  ),
  KidCostUserScenario(
    id: 'SHELL-01',
    area: 'Shell',
    actor: 'Zalogowany rodzic',
    action: 'moze przejsc do glownych sekcji produktu',
    timing: 'kiedy jest po onboardingu i korzysta z nawigacji shell',
    expectedOutcome:
        'Start, koszty, dodawanie, szablony, opieka, raporty, rodzina, plany, kosztorys i ustawienia sa osiagalne',
    coverage: ['widget_test: bottom navigation exposes the MVP demo sections'],
  ),
  KidCostUserScenario(
    id: 'PRIV-01',
    area: 'Privacy',
    actor: 'Zalogowany rodzic',
    action: 'ma ukrywane wrazliwe ekrany w podgladzie systemowym',
    timing: 'kiedy aplikacja przechodzi w stan inactive lub paused',
    expectedOutcome:
        'aplikacja zaslania dane rodzinne, a bezpieczne ustawienia pozostaja czytelne',
    coverage: [
      'widget_test: background preview hides sensitive shell screens only',
    ],
  ),
  KidCostUserScenario(
    id: 'DASH-01',
    area: 'Dashboard',
    actor: 'Rodzic bez kosztow w miesiacu',
    action: 'widzi jasna nastepna akcje dodania pierwszego kosztu',
    timing: 'kiedy otwiera dashboard po onboardingu',
    expectedOutcome:
        'empty state prowadzi do formularza kosztu bez tlumaczenia calej aplikacji',
    coverage: [
      'widget_test: dashboard shows empty state and CTA opens add expense',
    ],
  ),
  KidCostUserScenario(
    id: 'DASH-02',
    area: 'Dashboard',
    actor: 'Rodzic z kosztami w miesiacu',
    action: 'moze zobaczyc kto komu ile oddaje',
    timing: 'kiedy wraca na dashboard po zapisaniu kosztow',
    expectedOutcome: 'saldo i suma miesiaca sa zgodne z aktualnymi kosztami',
    coverage: [
      'widget_test: dashboard summarizes current month balance and recent costs',
    ],
  ),
  KidCostUserScenario(
    id: 'DASH-03',
    area: 'Dashboard',
    actor: 'Rodzic z kosztami wymagajacymi reakcji',
    action: 'widzi kolejke najwazniejszych spraw',
    timing: 'kiedy sa koszty oczekujace, sporne lub drafty',
    expectedOutcome:
        'attention queue pokazuje sprawy do decyzji przed historia',
    coverage: [
      'widget_test: dashboard attention queue prioritizes actionable expenses',
    ],
  ),
  KidCostUserScenario(
    id: 'DASH-04',
    area: 'Dashboard',
    actor: 'Rodzic robiacy szybki capture',
    action: 'moze zaczac prywatny draft paragonu',
    timing: 'kiedy chce zachowac dowod zanim uzupelni szczegoly',
    expectedOutcome:
        'aplikacja otwiera formularz kosztu w trybie draftu paragonu',
    coverage: [
      'widget_test: dashboard quick capture starts private receipt draft',
    ],
  ),
  KidCostUserScenario(
    id: 'EXP-01',
    area: 'Expenses',
    actor: 'Rodzic dodajacy koszt',
    action: 'moze zapisac koszt z kwota, data, kategoria, platnikiem i opisem',
    timing: 'kiedy ma nowy wydatek dziecka do rozliczenia',
    expectedOutcome: 'koszt pojawia sie na liscie i zmienia saldo',
    coverage: [
      'widget_test: saved expense appears on list and changes balance',
    ],
  ),
  KidCostUserScenario(
    id: 'EXP-02',
    area: 'Expenses',
    actor: 'Rodzic dodajacy koszt',
    action: 'nie moze zapisac kosztu bez poprawnej kwoty i daty',
    timing: 'kiedy formularz ma puste albo niepoprawne wymagane pola',
    expectedOutcome: 'formularz pokazuje blad i nie tworzy kosztu',
    coverage: ['widget_test: add expense validates amount and date'],
  ),
  KidCostUserScenario(
    id: 'EXP-03',
    area: 'Expenses',
    actor: 'Rodzic dodajacy koszt',
    action: 'moze dodac koszt przez szybkie kategorie bez obowiazkowego opisu',
    timing: 'kiedy chce zapisac prosty wydatek w mniej niz minute',
    expectedOutcome: 'kategoria moze pelnic role nazwy kosztu',
    coverage: [
      'widget_test: add expense uses quick categories and optional description',
    ],
  ),
  KidCostUserScenario(
    id: 'EXP-04',
    area: 'Expenses',
    actor: 'Rodzic dodajacy koszt uslugi',
    action: 'moze zapisac okres i zakres uslugi',
    timing: 'kiedy koszt dotyczy np. wielu obiadow, zajec lub konsultacji',
    expectedOutcome:
        'szczegoly okresu sa widoczne osobno od glownej daty kosztu',
    coverage: [
      'widget_test: add expense saves service period and shows it separately',
    ],
  ),
  KidCostUserScenario(
    id: 'EXP-05',
    area: 'Expenses',
    actor: 'Rodzic dodajacy koszt z paragonem w walucie obcej',
    action: 'widzi informacyjny guardrail walutowy',
    timing: 'kiedy waluta paragonu rozni sie od waluty rodziny',
    expectedOutcome:
        'aplikacja nie liczy kursow w MVP i prosi o kwote przeliczona na walute rodziny',
    coverage: [
      'widget_test: add expense keeps foreign receipt currency informational',
    ],
  ),
  KidCostUserScenario(
    id: 'EXP-06',
    area: 'Expenses',
    actor: 'Rodzic rozbijajacy jeden paragon',
    action: 'moze zapisac pozycje kosztu i przypisac je do kategorii',
    timing: 'kiedy jeden dowod obejmuje kilka typow wydatkow',
    expectedOutcome:
        'line items sa zachowane bez zmiany glownego algorytmu salda',
    coverage: [
      'widget_test: add expense saves reconciled line items for one receipt',
    ],
  ),
  KidCostUserScenario(
    id: 'EXP-07',
    area: 'Expenses',
    actor: 'Rodzic proszacy o zwrot',
    action: 'moze zapisac daty zgloszenia i terminy platnosci',
    timing: 'kiedy chce uporzadkowac follow-up do drugiego rodzica',
    expectedOutcome: 'terminy sa widoczne przy koszcie i w filtrach zaleglosci',
    coverage: ['widget_test: add expense saves reimbursement deadline dates'],
  ),
  KidCostUserScenario(
    id: 'EXP-08',
    area: 'Expenses',
    actor: 'Rodzic proszacy o platnosc do dostawcy',
    action: 'moze opisac dostawce, kwote, termin i status platnosci',
    timing:
        'kiedy drugi rodzic ma zaplacic bezposrednio placowce lub sprzedawcy',
    expectedOutcome:
        'prosba jest zapisana bez wykonywania platnosci i bez danych bankowych',
    coverage: ['widget_test: add expense saves pay-provider request details'],
  ),
  KidCostUserScenario(
    id: 'EXP-09',
    area: 'Expenses',
    actor: 'Rodzic dodajacy rachunek medyczny',
    action: 'moze zapisac EOB, dostawce i odpowiedzialnosc pacjenta',
    timing:
        'kiedy koszt medyczny wymaga dodatkowego kontekstu ubezpieczeniowego',
    expectedOutcome: 'pakiet medyczny nie zmienia kwoty proszonej do zwrotu',
    coverage: ['widget_test: add expense saves optional medical EOB packet'],
  ),
  KidCostUserScenario(
    id: 'EXP-10',
    area: 'Expenses',
    actor: 'Rodzic potwierdzajacy OCR',
    action: 'moze przejrzec rozpoznane pola przed zapisem',
    timing: 'kiedy koszt powstaje z draftu paragonu',
    expectedOutcome:
        'aplikacja wymaga swiadomego potwierdzenia zamiast cichego nadpisania',
    coverage: [
      'widget_test: add expense reviews OCR draft fields before saving receipt',
    ],
  ),
  KidCostUserScenario(
    id: 'EXP-11',
    area: 'Expenses',
    actor: 'Rodzic dodajacy koszt',
    action: 'moze powiazac koszt z wydarzeniem kalendarza opieki',
    timing: 'kiedy koszt dotyczy konkretnego dnia opieki',
    expectedOutcome:
        'wydarzenie pokazuje kontekst kosztu bez zmiany samego salda',
    coverage: ['widget_test: add expense can link an existing calendar event'],
  ),
  KidCostUserScenario(
    id: 'EXP-12',
    area: 'Expenses',
    actor: 'Rodzic dodajacy koszt',
    action: 'moze uzyc karty kontekstu dziecka jako podpowiedzi',
    timing: 'kiedy rodzina ma zapisane preferencje lub potrzeby dziecka',
    expectedOutcome:
        'formularz pokazuje sugestie bez automatycznego wysylania danych',
    coverage: ['widget_test: add expense can link a child info context card'],
  ),
  KidCostUserScenario(
    id: 'EXP-13',
    area: 'Expenses',
    actor: 'Rodzic dodajacy podobny rachunek',
    action: 'widzi neutralna sugestie mozliwego duplikatu',
    timing:
        'kiedy kwota, dostawca albo numer dokumentu pasuja do starego kosztu',
    expectedOutcome:
        'moze swiadomie kontynuowac albo przejsc do istniejacego wpisu',
    coverage: [
      'widget_test: add expense warns about similar bill and links related record',
    ],
  ),
  KidCostUserScenario(
    id: 'EXP-14',
    area: 'Expenses',
    actor: 'Rodzic w trybie solo',
    action: 'moze zapisac prywatny koszt z recznym platnikiem',
    timing: 'kiedy drugi rodzic nie jest jeszcze zaproszony do rodziny',
    expectedOutcome:
        'koszt pozostaje prywatny dla autora i nie tworzy konta drugiego rodzica',
    coverage: [
      'widget_test: solo mode saves private manual co-parent expenses',
    ],
  ),
  KidCostUserScenario(
    id: 'EXP-15',
    area: 'Expenses',
    actor: 'Drugi rodzic',
    action: 'moze zaakceptowac albo zakwestionowac oczekujacy koszt',
    timing: 'kiedy otwiera szczegoly kosztu wymagajacego reakcji',
    expectedOutcome:
        'status i historia kosztu zmieniaja sie bez emocjonalnego copy',
    coverage: [
      'widget_test: counterparty can accept or dispute a pending expense',
    ],
  ),
  KidCostUserScenario(
    id: 'EXP-16',
    area: 'Expenses',
    actor: 'Rodzic przegladajacy koszty',
    action: 'moze filtrowac liste i czyscic filtry',
    timing:
        'kiedy szuka kosztow po miesiacu, dziecku, kategorii, statusie lub platniku',
    expectedOutcome:
        'lista pokazuje tylko pasujace koszty i pozwala wrocic do pelnego widoku',
    coverage: [
      'widget_test: expenses list filters costs and can clear filters',
    ],
  ),
  KidCostUserScenario(
    id: 'EXP-17',
    area: 'Expenses',
    actor: 'Rodzic przegladajacy rozliczenia',
    action: 'moze zobaczyc zalegle terminy zwrotu',
    timing: 'kiedy koszty maja notice due albo payment due w przeszlosci',
    expectedOutcome: 'filtr zaleglosci pokazuje koszty wymagajace follow-upu',
    coverage: [
      'widget_test: expenses screen filters overdue reimbursement deadlines',
    ],
  ),
  KidCostUserScenario(
    id: 'PROOF-01',
    area: 'Proofs',
    actor: 'Rodzic dodajacy koszt',
    action: 'moze dolaczyc opcjonalny PDF lub obraz dowodu',
    timing: 'kiedy ma paragon, fakture albo potwierdzenie platnosci',
    expectedOutcome:
        'zalacznik jest zapisany przy koszcie i nie blokuje podstawowego ledgera',
    coverage: [
      'widget_test: optional PDF attachment is saved with the expense',
    ],
  ),
  KidCostUserScenario(
    id: 'PROOF-02',
    area: 'Proofs',
    actor: 'Rodzic dodajacy koszt',
    action: 'nie traci kosztu przy bledzie uploadu zalacznika',
    timing: 'kiedy zapis pliku nie powiedzie sie po wypelnieniu formularza',
    expectedOutcome:
        'koszt zostaje zapisany z czytelnym statusem bledu zalacznika',
    coverage: [
      'widget_test: attachment upload failure keeps the expense saved',
    ],
  ),
  KidCostUserScenario(
    id: 'PROOF-03',
    area: 'Proofs',
    actor: 'Rodzic lub raportujacy',
    action: 'moze przeszukac i filtrowac biblioteke dowodow',
    timing: 'kiedy przygotowuje raport albo chce znalezc paragon',
    expectedOutcome: 'filtry metadanych i zapytanie zawężaja widoczne dowody',
    coverage: [
      'widget_test: proof library searches and filters existing proofs',
    ],
  ),
  KidCostUserScenario(
    id: 'TPL-01',
    area: 'Templates',
    actor: 'Rodzic z powtarzalnym kosztem',
    action: 'moze zapisac szablon i utworzyc z niego koszt',
    timing: 'kiedy oplata wraca cyklicznie, np. przedszkole albo zajecia',
    expectedOutcome:
        'formularz kosztu jest wypelniony danymi szablonu do potwierdzenia',
    coverage: [
      'widget_test: recurring template prefills a manually confirmed expense',
    ],
  ),
  KidCostUserScenario(
    id: 'PLAN-01',
    area: 'Plans',
    actor: 'Rodzic planujacy zakup',
    action: 'moze utworzyc plan zakupu bez zmiany salda',
    timing: 'kiedy chce uzgodnic wydatek przed zakupem',
    expectedOutcome: 'plan trafia do listy planow i nie liczy sie jako koszt',
    coverage: [
      'widget_test: planned purchase screen creates plans outside balances',
    ],
  ),
  KidCostUserScenario(
    id: 'PLAN-02',
    area: 'Plans',
    actor: 'Rodzic po akceptacji planu',
    action: 'moze zamienic zatwierdzony plan w koszt',
    timing: 'kiedy zakup zostal uzgodniony i wykonany',
    expectedOutcome:
        'koszt powstaje z danych planu i dopiero wtedy wplywa na ledger',
    coverage: [
      'widget_test: approved planned purchase converts into an expense',
    ],
  ),
  KidCostUserScenario(
    id: 'CUST-01',
    area: 'Custody',
    actor: 'Rodzic prowadzacy kalendarz opieki',
    action: 'moze dodac zakres dni i edytowac pojedynczy dzien',
    timing: 'kiedy ustala plan opieki na miesiac',
    expectedOutcome: 'dni opieki zapisuja rodzica i sa widoczne w kalendarzu',
    coverage: [
      'widget_test: custody calendar adds a date range and edits a day',
    ],
  ),
  KidCostUserScenario(
    id: 'CUST-02',
    area: 'Custody',
    actor: 'Rodzic analizujacy dzien opieki',
    action: 'moze zobaczyc koszty i udzial drugiego rodzica dla dnia',
    timing: 'kiedy otwiera szczegoly dnia z powiazanymi kosztami',
    expectedOutcome:
        'dzień pokazuje opieke, koszty, terminy i udzialy finansowe',
    coverage: [
      'widget_test: custody day details show linked expenses and co-parent share',
    ],
  ),
  KidCostUserScenario(
    id: 'CUST-03',
    area: 'Custody',
    actor: 'Rodzic z dostepem Premium',
    action: 'moze przygotowac eksport ICS kalendarza',
    timing: 'kiedy chce przeniesc dni opieki do zewnetrznego kalendarza',
    expectedOutcome:
        'eksport jest bramkowany jako wygoda Premium i moze dolaczyc kontekst kosztow tylko po opt-in',
    coverage: [
      'widget_test: custody calendar gates ICS export as Premium convenience',
      'widget_test: custody ICS includes linked costs only after explicit opt-in',
    ],
  ),
  KidCostUserScenario(
    id: 'CUST-04',
    area: 'Custody',
    actor: 'Rodzic korzystajacy z typowego grafiku',
    action: 'moze wygenerowac preset opieki',
    timing: 'kiedy chce szybko wypelnic 14 dni wedlug schematu',
    expectedOutcome:
        'podglad pokazuje dni i pozwala zastosowac je do kalendarza',
    coverage: [
      'widget_test: custody calendar previews and applies a preset',
      'widget_test: custody preset generator supports common schedules',
    ],
  ),
  KidCostUserScenario(
    id: 'RPT-01',
    area: 'Reports',
    actor: 'Rodzic przygotowujacy rozliczenie miesieczne',
    action: 'moze zobaczyc podsumowanie kosztow i wyeksportowac CSV',
    timing: 'kiedy potrzebuje przejrzystego raportu za miesiac',
    expectedOutcome:
        'eksport zawiera koszty, statusy, saldo i kontekst bez ukrytych sum',
    coverage: [
      'widget_test: monthly reports summarize costs and expose CSV export',
    ],
  ),
  KidCostUserScenario(
    id: 'RPT-02',
    area: 'Reports',
    actor: 'Rodzic przygotowujacy raport',
    action: 'moze przejrzec dowody przed eksportem',
    timing: 'kiedy miesiac ma paragony lub faktury',
    expectedOutcome: 'raport pokazuje braki i oznacza dowody po eksporcie',
    coverage: [
      'widget_test: monthly reports review proofs before CSV export',
      'widget_test: monthly reports mark proofs after CSV export',
    ],
  ),
  KidCostUserScenario(
    id: 'RPT-03',
    area: 'Reports',
    actor: 'Rodzic lub mediator',
    action: 'widzi gotowosc dowodowa kosztow',
    timing: 'kiedy raport ma byc udostepniony poza aplikacja',
    expectedOutcome:
        'koszty z brakami dowodow sa pokazane oddzielnie od gotowych wpisow',
    coverage: [
      'widget_test: monthly reports show evidence readiness before export',
    ],
  ),
  KidCostUserScenario(
    id: 'RPT-04',
    area: 'Reports',
    actor: 'Rodzic raportujacy planowane zakupy',
    action: 'moze pokazac plany poza suma kosztow',
    timing: 'kiedy raport miesieczny zawiera niezrealizowane plany',
    expectedOutcome: 'plany sa kontekstem i nie podnosza salda kosztow',
    coverage: [
      'widget_test: monthly reports list planned purchases outside totals',
    ],
  ),
  KidCostUserScenario(
    id: 'RPT-05',
    area: 'Reports',
    actor: 'Rodzic dokumentujacy opieke',
    action: 'moze wlaczyc kontekst czasu rodzicielskiego',
    timing: 'kiedy raport ma pokazac dni opieki bez zmiany salda',
    expectedOutcome:
        'kontekst opieki trafia do raportu jako informacja, nie koszt',
    coverage: [
      'widget_test: monthly reports toggle parenting time context outside balance',
    ],
  ),
  KidCostUserScenario(
    id: 'RPT-06',
    area: 'Reports',
    actor: 'Rodzic w Polsce',
    action: 'moze dopisac zalozenia o swiadczeniach i podatkach',
    timing:
        'kiedy potrzebuje raportu z kontekstem 800+, Dobry Start, PIT lub opieki naprzemiennej',
    expectedOutcome:
        'zalozenia sa oddzielone od faktow kosztowych i nie zmieniaja salda',
    coverage: [
      'widget_test: report csv includes Polish benefit assumptions separately',
      'widget_test: monthly reports edit Polish context without changing balance',
    ],
  ),
  KidCostUserScenario(
    id: 'RPT-07',
    area: 'Reports',
    actor: 'Rodzic dokumentujacy stale przelewy',
    action: 'moze dodac kontekst alimentow lub stalego przelewu',
    timing:
        'kiedy przelew ma byc wyjasnieniem raportu, ale nie kosztem dziecka',
    expectedOutcome:
        'support context jest eksportowany osobno i nie zmienia bilansu',
    coverage: [
      'widget_test: reports export support context separately without changing balance',
      'widget_test: monthly reports add support context outside shared expense balance',
    ],
  ),
  KidCostUserScenario(
    id: 'RPT-08',
    area: 'Reports',
    actor: 'Rodzic analizujacy miesiac',
    action: 'moze przejsc z insightu raportu do filtrow kosztow',
    timing: 'kiedy chce zobaczyc skad wziela sie suma kategorii lub statusu',
    expectedOutcome:
        'lista kosztow otwiera pasujacy filtr bez recznego szukania',
    coverage: [
      'widget_test: monthly insights link report breakdowns to expense filters',
      'widget_test: expenses screen applies report filter requests',
    ],
  ),
  KidCostUserScenario(
    id: 'RPT-09',
    area: 'Reports',
    actor: 'Rodzic patrzacy szerzej niz jeden miesiac',
    action: 'moze wygenerowac raport roczny',
    timing: 'kiedy wybiera rok zamiast miesiaca',
    expectedOutcome: 'roczny eksport CSV podsumowuje koszty z wybranego roku',
    coverage: [
      'widget_test: annual reports summarize a selected year and expose CSV export',
    ],
  ),
  KidCostUserScenario(
    id: 'RPT-10',
    area: 'Reports',
    actor: 'Rodzic przygotowujacy material dla profesjonalisty',
    action: 'widzi guardrails profesjonalnego dostepu',
    timing: 'kiedy raport moze trafic do mediatora, prawnika albo doradcy',
    expectedOutcome:
        'aplikacja przypomina o ograniczonym zakresie i braku porady prawnej',
    coverage: [
      'widget_test: monthly reports expose professional access guardrails',
    ],
  ),
  KidCostUserScenario(
    id: 'COSTPLAN-01',
    area: 'Reports',
    actor: 'Rodzic planujacy budzet dziecka',
    action: 'moze porownac plan miesieczny z realnymi kosztami',
    timing: 'kiedy chce zrozumiec roznice per kategoria',
    expectedOutcome:
        'kosztorys pokazuje plan, actual i roznice bez zmiany ledgera',
    coverage: [
      'widget_test: monthly cost plan compares PL plan with actual expenses',
    ],
  ),
  KidCostUserScenario(
    id: 'FAM-01',
    area: 'Family',
    actor: 'Rodzic prowadzacy kontekst dziecka',
    action: 'moze tworzyc i edytowac karty informacji o dziecku',
    timing: 'kiedy potrzeby dziecka pomagaja opisywac koszty',
    expectedOutcome:
        'karty sa dostepne jako kontekst bez ujawniania ich w telemetryce',
    coverage: ['widget_test: family screen creates and edits child info cards'],
  ),
  KidCostUserScenario(
    id: 'SET-01',
    area: 'Settings',
    actor: 'Rodzic konfigurujacy powiadomienia',
    action: 'moze ustawic prywatne podglady, tryb dostawy i cisze nocna',
    timing: 'kiedy chce ograniczyc eskalacje i dane na ekranie blokady',
    expectedOutcome: 'ustawienia opisuja skutki bez wymuszania pushy',
    coverage: [
      'widget_test: settings exposes contextual notification controls',
    ],
  ),
  KidCostUserScenario(
    id: 'SET-02',
    area: 'Settings',
    actor: 'Rodzic konfigurujacy rozliczenia',
    action: 'moze wybrac regule podzialu kosztow rodziny',
    timing: 'kiedy rodzina nie uzywa prostego 50/50',
    expectedOutcome: 'dashboard i saldo uzywaja aktywnej reguly',
    coverage: [
      'widget_test: settings exposes family settlement split choices',
      'widget_test: dashboard recalculates balance with 70/30 split rule',
    ],
  ),
  KidCostUserScenario(
    id: 'SET-03',
    area: 'Settings',
    actor: 'Rodzic dbajacy o dane',
    action: 'moze przygotowac request eksportu danych rodziny',
    timing: 'kiedy potrzebuje kopii lub chce zamknac etap testow',
    expectedOutcome:
        'aplikacja pokazuje zakres eksportu i nie wysyla danych bez swiadomej akcji',
    coverage: [
      'widget_test: settings exposes family data export request scope',
    ],
  ),
  KidCostUserScenario(
    id: 'SET-04',
    area: 'Settings',
    actor: 'Tester beta',
    action: 'moze przygotowac privacy-safe feedback',
    timing: 'kiedy chce zglosic blad bez danych dziecka i pelnych kwot',
    expectedOutcome:
        'szablon feedbacku prowadzi przez kroki i chroni dane rodzinne',
    coverage: [
      'widget_test: settings prepares safe beta feedback without PII telemetry',
    ],
  ),
  KidCostUserScenario(
    id: 'PREM-01',
    area: 'Premium',
    actor: 'Rodzic rozwazajacy Premium',
    action: 'widzi spokojne i mozliwe do zamkniecia podpowiedzi Premium',
    timing: 'kiedy trafia na funkcje wykraczajaca poza Free',
    expectedOutcome:
        'premium discovery nie blokuje podstawowego przeplywu kosztow',
    coverage: ['widget_test: premium discovery stays calm and dismissible'],
  ),
  KidCostUserScenario(
    id: 'PREM-02',
    area: 'Premium',
    actor: 'Rodzic rezygnujacy z planu',
    action: 'widzi co zostanie dostepne po downgrade',
    timing: 'kiedy otwiera przeplyw anulowania lub zmiany planu',
    expectedOutcome:
        'historia pozostaje czytelna, a ograniczenia dotycza nowych funkcji Premium',
    coverage: [
      'widget_test: settings downgrade flow preserves records and safe telemetry',
    ],
  ),
  KidCostUserScenario(
    id: 'REL-01',
    area: 'Release',
    actor: 'Zespol release',
    action: 'moze sprawdzic konfiguracje kanalu beta i obserwowalnosci',
    timing: 'kiedy przygotowuje build testowy',
    expectedOutcome:
        'testy konfiguracyjne wykrywaja niedokonczona obserwowalnosc bez blokowania demo',
    coverage: ['app_config_test: beta build metadata and observability gates'],
  ),
  KidCostUserScenario(
    id: 'REL-02',
    area: 'Release',
    actor: 'Zespol produktu',
    action: 'moze liczyc na telemetryke bez PII i precyzyjnych kwot',
    timing:
        'kiedy aplikacja emituje zdarzenia auth, kosztow, statusow lub raportow',
    expectedOutcome:
        'payload techniczny nie zawiera emaili, imion dzieci, opisow ani kwot',
    coverage: [
      'telemetry_test: privacy-safe telemetry sanitizes event payloads',
    ],
  ),
  KidCostUserScenario(
    id: 'REL-03',
    area: 'Release',
    actor: 'Zespol produktu',
    action: 'moze sanitizowac zalaczniki przed uploadem',
    timing: 'kiedy uzytkownik dolacza JPEG, PNG albo PDF',
    expectedOutcome:
        'EXIF i metadane PNG sa usuwane, a PDF pozostaje binarnie stabilny',
    coverage: [
      'attachment_storage_test: sanitizeAttachmentForUpload strips metadata',
    ],
  ),
];
