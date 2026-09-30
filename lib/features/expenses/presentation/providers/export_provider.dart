import 'dart:ui';

import 'package:expense_tracker/core/sharing/file_sharer.dart';
import 'package:expense_tracker/features/expenses/data/expense_repository_provider.dart';
import 'package:expense_tracker/features/expenses/domain/calendar_month.dart';
import 'package:expense_tracker/features/expenses/domain/expense_repository.dart';
import 'package:expense_tracker/features/expenses/presentation/expense_csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ExportResult {
  /// The share sheet was opened with the file.
  shared,

  /// The month has no expenses, so no file was made.
  nothingToExport,
}

/// Exports one month of expenses as a CSV file through the share sheet.
///
/// Its dependencies are passed in, so tests can give it a fake repository
/// and a fake sharer without any Riverpod setup.
class ExpenseExporter {
  ExpenseExporter({required this._repository, required this._sharer});

  final ExpenseRepository _repository;
  final FileSharer _sharer;

  /// Throws if the file cannot be shared; the caller shows the error.
  Future<ExportResult> exportMonth(CalendarMonth month, {Rect? origin}) async {
    // .first: the month's expenses once, as they are right now.
    final expenses = await _repository.watchMonth(month).first;
    if (expenses.isEmpty) return ExportResult.nothingToExport;

    await _sharer.shareTextFile(
      fileName: exportFileName(month),
      contents: expensesToCsv(expenses),
      mimeType: 'text/csv',
      origin: origin,
    );
    return ExportResult.shared;
  }
}

final expenseExporterProvider = Provider<ExpenseExporter>(
  (ref) => ExpenseExporter(
    repository: ref.watch(expenseRepositoryProvider),
    sharer: ref.watch(fileSharerProvider),
  ),
);
