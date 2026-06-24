import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidcost_mobile/src/features/expenses/attachment_storage.dart';
import 'package:kidcost_mobile/src/features/expenses/expense_models.dart';

void main() {
  test('sanitizeAttachmentForUpload strips JPEG EXIF APP1 metadata', () {
    final draft = AttachmentDraft(
      fileName: 'receipt.jpg',
      contentType: 'image/jpeg',
      bytes: Uint8List.fromList([
        0xff, 0xd8,
        ..._jpegSegment(0xe1, [
          0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // Exif header.
          0x47, 0x50, 0x53, // GPS-like payload.
        ]),
        ..._jpegSegment(0xe2, [0x49, 0x43, 0x43]),
        0xff, 0xda, 0x00, 0x02, // Start of scan.
        0x11, 0x22, 0xff, 0xd9,
      ]),
    );

    final sanitized = sanitizeAttachmentForUpload(draft);

    expect(sanitized.fileName, 'receipt.jpg');
    expect(sanitized.contentType, 'image/jpeg');
    expect(
      sanitized.bytes,
      isNot(containsAllInOrder([0x45, 0x78, 0x69, 0x66])),
    );
    expect(sanitized.bytes, containsAllInOrder([0x49, 0x43, 0x43]));
    expect(sanitized.bytes, containsAllInOrder([0xff, 0xda, 0x00, 0x02]));
  });

  test('sanitizeAttachmentForUpload normalizes image content type', () {
    final draft = AttachmentDraft(
      fileName: 'receipt.jpg',
      contentType: ' Image/JPEG; charset=binary ',
      bytes: Uint8List.fromList([
        0xff,
        0xd8,
        ..._jpegSegment(0xe1, [
          0x45,
          0x78,
          0x69,
          0x66,
          0x00,
          0x00,
          0x47,
          0x50,
          0x53,
        ]),
        0xff,
        0xda,
        0x00,
        0x02,
        0x11,
        0x22,
        0xff,
        0xd9,
      ]),
    );

    final sanitized = sanitizeAttachmentForUpload(draft);

    expect(
      sanitized.bytes,
      isNot(containsAllInOrder([0x45, 0x78, 0x69, 0x66])),
    );
  });

  test('sanitizeAttachmentForUpload strips PNG metadata chunks', () {
    final draft = AttachmentDraft(
      fileName: 'receipt.png',
      contentType: 'image/png',
      bytes: Uint8List.fromList([
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        ..._pngChunk('IHDR', [0x00]),
        ..._pngChunk('eXIf', [0x47, 0x50, 0x53]),
        ..._pngChunk('tEXt', [0x4c, 0x6f, 0x63]),
        ..._pngChunk('IDAT', [0x01, 0x02]),
        ..._pngChunk('IEND', []),
      ]),
    );

    final sanitized = sanitizeAttachmentForUpload(draft);
    final sanitizedText = String.fromCharCodes(sanitized.bytes);

    expect(sanitized.fileName, 'receipt.png');
    expect(sanitizedText, contains('IHDR'));
    expect(sanitizedText, contains('IDAT'));
    expect(sanitizedText, contains('IEND'));
    expect(sanitizedText, isNot(contains('eXIf')));
    expect(sanitizedText, isNot(contains('tEXt')));
  });

  test('sanitizeAttachmentForUpload leaves PDF attachments unchanged', () {
    final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
    final draft = AttachmentDraft(
      fileName: 'invoice.pdf',
      contentType: 'application/pdf',
      bytes: bytes,
    );

    final sanitized = sanitizeAttachmentForUpload(draft);

    expect(identical(sanitized, draft), isTrue);
    expect(identical(sanitized.bytes, bytes), isTrue);
  });
}

List<int> _jpegSegment(int marker, List<int> payload) {
  final length = payload.length + 2;
  return [0xff, marker, length >> 8, length & 0xff, ...payload];
}

List<int> _pngChunk(String type, List<int> data) {
  final length = data.length;
  return [
    (length >> 24) & 0xff,
    (length >> 16) & 0xff,
    (length >> 8) & 0xff,
    length & 0xff,
    ...type.codeUnits,
    ...data,
    0x00,
    0x00,
    0x00,
    0x00,
  ];
}
