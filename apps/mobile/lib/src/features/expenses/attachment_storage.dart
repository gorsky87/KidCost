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
    return AttachmentUploadResult(
      storagePath: 'demo-storage/$expenseId/${attachment.fileName}',
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
    final safeName = attachment.fileName.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );
    final path = '$expenseId/$safeName';
    await _client.storage
        .from('expense-attachments')
        .uploadBinary(
          path,
          attachment.bytes,
          fileOptions: FileOptions(contentType: attachment.contentType),
        );
    return AttachmentUploadResult(storagePath: path);
  }
}
