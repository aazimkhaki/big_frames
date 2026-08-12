import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  final appDir = await getApplicationSupportDirectory();
  final dbPath = p.join(appDir.path, 'wasabi_client.db');
  
  final db = sqlite3.open(dbPath);
  
  // Initialize tables
  db.execute('''
    CREATE TABLE IF NOT EXISTS connections (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      accessKey TEXT NOT NULL,
      region TEXT NOT NULL,
      endpoint TEXT NOT NULL
    );
  ''');
  
  db.execute('''
    CREATE TABLE IF NOT EXISTS transfers (
      id TEXT PRIMARY KEY,
      connectionId TEXT NOT NULL,
      bucketName TEXT NOT NULL,
      objectKey TEXT NOT NULL,
      localFilePath TEXT NOT NULL,
      type TEXT NOT NULL,
      totalBytes INTEGER NOT NULL,
      transferredBytes INTEGER NOT NULL DEFAULT 0,
      status TEXT NOT NULL,
      errorMessage TEXT
    );
  ''');
  
  db.execute('''
    CREATE TABLE IF NOT EXISTS multipart_checkpoints (
      transferId TEXT PRIMARY KEY,
      uploadId TEXT NOT NULL,
      partsJson TEXT NOT NULL,
      FOREIGN KEY(transferId) REFERENCES transfers(id) ON DELETE CASCADE
    );
  ''');

  return db;
});
