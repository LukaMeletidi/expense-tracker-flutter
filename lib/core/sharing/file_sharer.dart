import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a file to the phone's share sheet, where the user picks where it
/// goes (Files, Drive, email, ...).
///
/// An interface, so tests can replace it with a fake: plugins such as
/// share_plus do not run inside `flutter test`.
abstract class FileSharer {
  /// Shares a text file called [fileName] containing [contents].
  ///
  /// [origin] is where the share sheet points from on iPad; phones ignore it.
  Future<void> shareTextFile({
    required String fileName,
    required String contents,
    required String mimeType,
    Rect? origin,
  });
}

/// The real [FileSharer], using the share_plus plugin.
///
/// No storage permission is needed: share_plus writes the file into the
/// app's own temporary folder and passes it to the share sheet.
class SharePlusFileSharer implements FileSharer {
  @override
  Future<void> shareTextFile({
    required String fileName,
    required String contents,
    required String mimeType,
    Rect? origin,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(utf8.encode(contents), mimeType: mimeType)],
        // A file made from data has no name of its own; this sets it.
        fileNameOverrides: [fileName],
        sharePositionOrigin: origin,
      ),
    );
  }
}

final fileSharerProvider = Provider<FileSharer>((ref) => SharePlusFileSharer());
