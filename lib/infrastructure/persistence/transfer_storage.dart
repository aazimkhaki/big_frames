import 'package:sqlite3/sqlite3.dart';
import 'package:big_frames/domain/models/transfer_task.dart';

class TransferStorage {
  final Database _db;

  TransferStorage(this._db);

  List<TransferTask> getAllTransfers() {
    final resultSet = _db.select('SELECT * FROM transfers ORDER BY rowid DESC');
    return resultSet.map((row) => _fromRow(row)).toList();
  }

  void saveTransfer(TransferTask task) {
    final stmt = _db.prepare('''
      INSERT INTO transfers (id, connectionId, bucketName, objectKey, localFilePath, type, totalBytes, transferredBytes, status, errorMessage)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        transferredBytes=excluded.transferredBytes,
        status=excluded.status,
        errorMessage=excluded.errorMessage;
    ''');
    
    stmt.execute([
      task.id,
      task.connectionId,
      task.bucketName,
      task.objectKey,
      task.localFilePath,
      task.type.name,
      task.totalBytes,
      task.transferredBytes,
      task.status.name,
      task.errorMessage,
    ]);
    stmt.dispose();
  }
  
  void deleteTransfer(String id) {
    final stmt = _db.prepare('DELETE FROM transfers WHERE id = ?');
    stmt.execute([id]);
    stmt.dispose();
  }

  void updateTransferStatus(String id, TransferStatus status, {String? error}) {
    final stmt = _db.prepare('UPDATE transfers SET status = ?, errorMessage = ? WHERE id = ?');
    stmt.execute([status.name, error, id]);
    stmt.dispose();
  }
  
  void updateTransferProgress(String id, int transferredBytes) {
    final stmt = _db.prepare('UPDATE transfers SET transferredBytes = ? WHERE id = ?');
    stmt.execute([transferredBytes, id]);
    stmt.dispose();
  }

  TransferTask _fromRow(Row row) {
    return TransferTask(
      id: row['id'] as String,
      connectionId: row['connectionId'] as String,
      bucketName: row['bucketName'] as String,
      objectKey: row['objectKey'] as String,
      localFilePath: row['localFilePath'] as String,
      type: TransferType.values.firstWhere((e) => e.name == row['type']),
      totalBytes: row['totalBytes'] as int,
      transferredBytes: row['transferredBytes'] as int,
      status: TransferStatus.values.firstWhere((e) => e.name == row['status']),
      errorMessage: row['errorMessage'] as String?,
    );
  }
}
