import 'package:drift/native.dart';
import 'package:expense_tracker/core/clock/clock_provider.dart';
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Now" in provider tests, so they show September 2026 whatever the real
/// date is.
final testNow = DateTime(2026, 9, 29, 12, 0);

/// A container whose database lives in memory and whose clock is pinned to
/// [testNow]. Only those two are replaced, so the real repository and
/// providers are under test.
///
/// ProviderContainer.test disposes the container when the test ends, and
/// with it the database: ref.onDispose closes it.
ProviderContainer createInMemoryContainer() {
  return ProviderContainer.test(
    overrides: [
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase(NativeDatabase.memory());
        ref.onDispose(db.close);
        return db;
      }),
      clockProvider.overrideWithValue(() => testNow),
    ],
  );
}
