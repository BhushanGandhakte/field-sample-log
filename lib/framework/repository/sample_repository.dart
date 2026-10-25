import 'package:field_sample_log/framework/database/app_database.dart';
import 'package:field_sample_log/framework/model/sample_model.dart';
import 'package:sqflite/sqflite.dart';

class SampleRepository {
  // The repository uses this database to save and retrieve samples.
  // Keeping database access here prevents the UI from handling SQL queries.
  final AppDatabase _database;

  // Allow a database instance to be passed in for testing.
  // Otherwise, use the shared database instance used by the application.
  SampleRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  // Fetch all saved samples, showing the most recently collected ones first.
  // The ID is used as a secondary sort so samples collected at the same time
  // still appear in a consistent order.
  Future<List<SampleModel>> getAllSamples() async {
    final db = await _database.database;

    final List<Map<String, Object?>> maps = await db.query(
      'samples',
      orderBy: 'collected_at DESC, id DESC',
    );

    // Convert the raw database rows into SampleModel objects
    // so the rest of the app can work with typed data.
    return maps.map((map) => SampleModel.fromMap(map)).toList();
  }

  // Find one sample by its database ID.
  // Returning null means the sample doesn't exist anymore.
  Future<SampleModel?> getSampleById(int id) async {
    final db = await _database.database;

    final List<Map<String, Object?>> maps = await db.query(
      'samples',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return SampleModel.fromMap(maps.first);
    }

    return null;
  }

  // Save a new sample and return the ID SQLite assigns to it.
  Future<int> insertSample(SampleModel sample) async {
    final db = await _database.database;

    // A new sample doesn't have an ID yet, so leave it out of the insert.
    // This lets SQLite generate the ID automatically.
    final values = sample.toMap()
      ..removeWhere((key, value) => key == 'id' && value == null);

    return await db.insert(
      'samples',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Save changes to an existing sample.
  // The ID identifies which database row should be updated.
  Future<int> updateSample(SampleModel sample) async {
    final db = await _database.database;

    return await db.update(
      'samples',
      sample.toMap(),
      where: 'id = ?',
      whereArgs: [sample.id],
    );
  }

  // Delete a sample by its ID.
  // The returned value is the number of rows that were deleted.
  Future<int> deleteSample(int id) async {
    final db = await _database.database;

    return await db.delete('samples', where: 'id = ?', whereArgs: [id]);
  }
}
