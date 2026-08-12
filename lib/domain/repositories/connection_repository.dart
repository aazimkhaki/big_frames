import 'package:big_frames/domain/models/connection.dart';

abstract class ConnectionRepository {
  Future<List<S3Connection>> getConnections();
  Future<S3Connection?> getConnection(String id);
  Future<void> saveConnection(S3Connection connection, String secretKey);
  Future<void> deleteConnection(String id);
}
