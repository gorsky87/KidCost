# KidCost Reimbursement Request Package

Data: 2026-06-24

Wykonywalny kontrakt domenowy znajduje sie w `packages/domain/lib/src/reimbursement_request_package.dart`.

## Packet content

- total amount,
- requested share,
- itemized expense rows with child/category/date/status,
- receipt/evidence state,
- optional note,
- trust footer,
- neutral timeline label: `Request sent` / `Waiting for response`.

## Delivery modes

- `shareSheet`: local MVP share output, no KidCost account required.
- `emailReadyCopy`: fallback when backend token is not available.
- `secureReadOnlyLink`: scoped token, no account required, must have expiry.

Sharing a packet does not grant broader family access and does not bypass invite acceptance.

## Non-promises

The packet is not legal advice, court certification, payment processing, bank transfer, BLIK, Venmo, or payment verification. It is a clean family expense record packet.

## Analytics

Allowed properties: `delivery_channel`, `expense_count`, `recipient_access_mode`.

Do not send amount, child id, expense id, receipt id, recipient email, note text, family id, or co-parent id.
