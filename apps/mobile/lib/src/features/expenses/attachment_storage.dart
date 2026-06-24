import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'expense_models.dart';

class AttachmentUploadResult {
  const AttachmentUploadResult({required this.storagePath});

  final String storagePath;
}

abstract class AttachmentStorage {
  Future<AttachmentUploadResult> upload({
    required String expenseId,
    required AttachmentDraft attachment,
  });
}

class InMemoryAttachmentStorage implements AttachmentStorage {
  @override
  Future<AttachmentUploadResult> upload({
    required String expenseId,
    required AttachmentDraft attachment,
  }) async {
    final sanitized = sanitizeAttachmentForUpload(attachment);
    return AttachmentUploadResult(
      storagePath: 'demo-storage/$expenseId/${sanitized.fileName}',
    );
  }
}

class SupabaseAttachmentStorage implements AttachmentStorage {
  SupabaseAttachmentStorage(this._client);

  final SupabaseClient _client;

  @override
  Future<AttachmentUploadResult> upload({
    required String expenseId,
    required AttachmentDraft attachment,
  }) async {
    final sanitized = sanitizeAttachmentForUpload(attachment);
    final safeName = sanitized.fileName.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );
    final path = '$expenseId/$safeName';
    await _client.storage
        .from('expense-attachments')
        .uploadBinary(
          path,
          sanitized.bytes,
          fileOptions: FileOptions(contentType: sanitized.contentType),
        );
    return AttachmentUploadResult(storagePath: path);
  }
}

AttachmentDraft sanitizeAttachmentForUpload(AttachmentDraft attachment) {
  final sanitizedBytes = switch (attachment.contentType) {
    'image/jpeg' || 'image/jpg' => _stripJpegExif(attachment.bytes),
    'image/png' => _stripPngMetadata(attachment.bytes),
    _ => attachment.bytes,
  };

  if (identical(sanitizedBytes, attachment.bytes)) {
    return attachment;
  }

  return AttachmentDraft(
    fileName: attachment.fileName,
    contentType: attachment.contentType,
    bytes: sanitizedBytes,
  );
}

Uint8List _stripJpegExif(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
    return bytes;
  }

  final output = BytesBuilder(copy: false)..add(bytes.sublist(0, 2));
  var offset = 2;

  while (offset < bytes.length) {
    if (bytes[offset] != 0xff) {
      output.add(bytes.sublist(offset));
      return output.toBytes();
    }

    var markerStart = offset;
    while (offset < bytes.length && bytes[offset] == 0xff) {
      offset++;
    }
    if (offset >= bytes.length) {
      output.add(bytes.sublist(markerStart));
      return output.toBytes();
    }

    final marker = bytes[offset++];
    if (marker == 0xd8 || marker == 0xd9) {
      output.add(bytes.sublist(markerStart, offset));
      continue;
    }
    if (marker == 0xda) {
      output.add(bytes.sublist(markerStart));
      return output.toBytes();
    }
    if (offset + 2 > bytes.length) {
      return bytes;
    }

    final segmentLength = (bytes[offset] << 8) | bytes[offset + 1];
    if (segmentLength < 2 || offset + segmentLength > bytes.length) {
      return bytes;
    }

    final segmentStart = markerStart;
    final segmentEnd = offset + segmentLength;
    final isExifApp1 = marker == 0xe1 && _hasExifHeader(bytes, offset + 2);
    if (!isExifApp1) {
      output.add(bytes.sublist(segmentStart, segmentEnd));
    }
    offset = segmentEnd;
  }

  return output.toBytes();
}

bool _hasExifHeader(Uint8List bytes, int offset) {
  const exifHeader = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00];
  if (offset + exifHeader.length > bytes.length) return false;
  for (var index = 0; index < exifHeader.length; index++) {
    if (bytes[offset + index] != exifHeader[index]) return false;
  }
  return true;
}

Uint8List _stripPngMetadata(Uint8List bytes) {
  const signature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (bytes.length < signature.length) return bytes;
  for (var index = 0; index < signature.length; index++) {
    if (bytes[index] != signature[index]) return bytes;
  }

  final output = BytesBuilder(copy: false)..add(bytes.sublist(0, 8));
  var offset = 8;

  while (offset < bytes.length) {
    if (offset + 12 > bytes.length) return bytes;

    final length =
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    if (length < 0 || offset + 12 + length > bytes.length) return bytes;

    final typeOffset = offset + 4;
    final type = String.fromCharCodes(
      bytes.sublist(typeOffset, typeOffset + 4),
    );
    final chunkEnd = offset + 12 + length;
    final shouldStrip =
        type == 'eXIf' || type == 'tEXt' || type == 'zTXt' || type == 'iTXt';
    if (!shouldStrip) {
      output.add(bytes.sublist(offset, chunkEnd));
    }

    offset = chunkEnd;
    if (type == 'IEND') break;
  }

  return output.toBytes();
}
