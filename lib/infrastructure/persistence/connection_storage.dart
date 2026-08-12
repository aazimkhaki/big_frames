import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:big_frames/core/secure_storage.dart';
import 'package:big_frames/domain/models/connection.dart';
import 'package:big_frames/domain/repositories/connection_repository.dart';
import 'package:big_frames/infrastructure/persistence/database_provider.dart';

final connectionRepositoryProvider = FutureProvider<ConnectionRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return SqliteConnectionStorage(db, secureStorage);
});

class SqliteConnectionStorage implements ConnectionRepository {
  final Database _db;
  final SecureStorageService _secureStorage;

  SqliteConnectionStorage(this._db, this._secureStorage);

  @override
  Future<List<S3Connection>> getConnections() async {
    final resultSet = _db.select('SELECT * FROM connections');
    final List<S3Connection> connections = [];
    
    for (final row in resultSet) {
      final id = row['id'] as String;
      final secretKey = await _secureStorage.getSecretKey(id);

      if (secretKey == null || secretKey.isEmpty) {
        throw Exception('Secret key not found for connection "${row['name']}". Please re-add the connection.');
      }

      connections.add(S3Connection(
        id: id,
        name: row['name'] as String,
        accessKey: row['accessKey'] as String,
        secretKey: secretKey,
        region: row['region'] as String,
        endpoint: row['endpoint'] as String,
      ));
    }
    return connections;
  }

  @override
  Future<S3Connection?> getConnection(String id) async {
    final stmt = _db.prepare('SELECT * FROM connections WHERE id = ?');
    final resultSet = stmt.select([id]);
    stmt.dispose();
    
    if (resultSet.isEmpty) return null;

    final row = resultSet.first;
    final secretKey = await _secureStorage.getSecretKey(id);

    if (secretKey == null || secretKey.isEmpty) {
      throw Exception('Secret key not found for connection "${row['name']}". Please re-add the connection.');
    }

    return S3Connection(
      id: id,
      name: row['name'] as String,
      accessKey: row['accessKey'] as String,
      secretKey: secretKey,
      region: row['region'] as String,
      endpoint: row['endpoint'] as String,
    );
  }

  @override
  Future<void> saveConnection(S3Connection connection, String secretKey) async {
    final stmt = _db.prepare('''
      INSERT INTO connections (id, name, accessKey, region, endpoint)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name=excluded.name,
        accessKey=excluded.accessKey,
        region=excluded.region,
        endpoint=excluded.endpoint;
    ''');
    
    stmt.execute([
      connection.id,
      connection.name,
      connection.accessKey,
      connection.region,
      connection.endpoint,
    ]);
    stmt.dispose();
    
    await _secureStorage.saveSecretKey(connection.id, secretKey);
  }

  @override
  Future<void> deleteConnection(String id) async {
    final stmt = _db.prepare('DELETE FROM connections WHERE id = ?');
    stmt.execute([id]);
    stmt.dispose();
    
    await _secureStorage.deleteSecretKey(id);
  }
}
