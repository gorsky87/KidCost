# KidCost - receipt OCR beta

Data: 2026-06-24
Zakres: issue #33

## Decyzja MVP

OCR jest funkcja `beta/later`, a nie czescia krytycznej sciezki dodawania kosztu.
Manualnie wpisana kwota, data, kategoria i opis pozostaja zrodlem prawdy do momentu, gdy uzytkownik swiadomie zaakceptuje propozycje OCR.

Pierwszy kandydat techniczny: Supabase Edge Function uruchamiana po dodaniu `expense_attachments`, ktora pobiera prywatny plik przez service role i wysyla go do Google Cloud Vision API `DOCUMENT_TEXT_DETECTION`.
Na etapie beta mozna porownac to z Google Document AI Enterprise Document OCR.

Oficjalne punkty odniesienia cenowe z 2026-06-24:

- Google Cloud Vision API: Text Detection i Document Text Detection maja bezplatne pierwsze 1000 jednostek miesiecznie, potem cennik per 1000 jednostek. Zrodlo: https://cloud.google.com/vision/pricing
- Google Document AI: Enterprise Document OCR jest rozliczany per strona; strona produktu pokazuje OCR od 1,50 USD za 1000 stron dla progu 1-5 mln stron miesiecznie, a cennik podaje przyklady rozliczania pakietow stron. Zrodla: https://cloud.google.com/document-ai oraz https://cloud.google.com/document-ai/pricing

Wniosek dla KidCost: zaczac od Vision API jako prostszego eksperymentu OCR dla pojedynczych paragonow, a Document AI sprawdzic dopiero, gdy bedziemy potrzebowali lepszej struktury dokumentu albo batch processingu.

## Dane

Migracja dodaje `public.ocr_results` powiazane z `expense_attachments`.
Attachment tworzy automatycznie wpis `queued`.
Backend zapisuje wynik przez `public.save_ocr_result(...)`.

Statusy:

- `queued`: attachment czeka na pipeline OCR.
- `processed`: OCR zakonczony i ma wynik techniczny.
- `needs_review`: wynik jest gotowy, ale wymaga potwierdzenia uzytkownika.
- `failed`: OCR nie udal sie; koszt i attachment pozostaja poprawne.

Minimalne pola wyniku:

- `extracted_amount`,
- `extracted_currency`,
- `extracted_date`,
- `merchant`,
- `confidence`,
- `raw_response`,
- `error_message`.

`requires_review` zostaje ustawione dla `processed` i `needs_review`.

## Zasady bezpieczenstwa

- OCR wynik dziedziczy dostep z attachmentu i kosztu przez RLS.
- Uzytkownik spoza rodziny nie widzi wyniku OCR.
- OCR nie aktualizuje `expenses.amount`, `expenses.expense_date` ani `expenses.description`.
- Bledy OCR sa zapisywane w `ocr_results.status = failed`, a dodawanie kosztu dziala dalej.
- Payload UI powinien pokazywac propozycje jako `do potwierdzenia`, nie jako automatycznie zaakceptowany koszt.

## Kontrakt dla ekranu potwierdzenia

Flutter moze czytac `ocr_results` dla attachmentu i pokazac:

```json
{
  "status": "needs_review",
  "requiresReview": true,
  "suggestions": {
    "amount": "42.99",
    "currency": "PLN",
    "date": "2026-06-23",
    "merchant": "Receipt Shop",
    "confidence": 0.84
  }
}
```

Ekran potwierdzenia powinien miec trzy akcje:

- zastosuj wybrane pola,
- popraw recznie,
- zignoruj OCR.

Automatyczne ksiegowanie bez potwierdzenia pozostaje poza zakresem.
