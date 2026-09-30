import 'dart:async';
import 'dart:ui';

import 'package:expense_tracker/core/sharing/file_sharer.dart';

/// One call to [FakeFileSharer.shareTextFile].
class SharedFile {
  const SharedFile(this.fileName, this.contents, this.mimeType, this.origin);

  final String fileName;
  final String contents;
  final String mimeType;
  final Rect? origin;
}

/// A [FileSharer] that records what it was asked to share instead of
/// opening a share sheet (which cannot happen inside `flutter test`).
class FakeFileSharer implements FileSharer {
  /// Every file shared, in order.
  final List<SharedFile> shared = [];

  /// When set, sharing fails with this error.
  Object? error;

  /// When set, sharing waits for this to complete, so a test can look at the
  /// screen while an export is still running.
  Completer<void>? gate;

  @override
  Future<void> shareTextFile({
    required String fileName,
    required String contents,
    required String mimeType,
    Rect? origin,
  }) async {
    await gate?.future;
    if (error != null) throw error!;
    shared.add(SharedFile(fileName, contents, mimeType, origin));
  }
}
