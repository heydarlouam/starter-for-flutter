// lib/data/repository/base_crud_repository.dart

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite_flutter_starter_kit/config/network/api_result.dart';
import 'package:appwrite_flutter_starter_kit/config/network/appwrite_client.dart';
import 'package:appwrite_flutter_starter_kit/config/network/request_executor.dart';

class BaseCrudRepository<T> {
  final String databaseId;
  final String collectionId;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T value) toJson;

  final Databases _databases;
  final RequestExecutor _executor;

  BaseCrudRepository({
    required this.databaseId,
    required this.collectionId,
    required this.fromJson,
    required this.toJson,
    Databases? databases,
    RequestExecutor? executor,
  })  : _databases = databases ?? AppwriteClient.instance.databases,
        _executor = executor ?? const RequestExecutor();

  Map<String, dynamic> _documentToMap(models.Document doc) {
    final map = <String, dynamic>{};
    map.addAll(doc.data);
    map['\$id'] = doc.$id;
    map['\$collectionId'] = doc.$collectionId;
    map['\$databaseId'] = doc.$databaseId;
    map['\$createdAt'] = doc.$createdAt;
    map['\$updatedAt'] = doc.$updatedAt;
    map['\$permissions'] = doc.$permissions;
    return map;
  }

  Future<ApiResult<List<T>>> getAll({List<String>? queries}) async {
    final result = await _executor.execute<models.DocumentList>(() {
      return _databases.listDocuments(

        databaseId: databaseId,
        collectionId: collectionId,
        queries: queries,

      );
    });

    if (result.isFailure) {
      return ApiResult.failure(result.requireError);
    }

    final docs = result.requireData.documents;
    final items = docs.map((doc) => fromJson(_documentToMap(doc))).toList();

    return ApiResult.success(items);
  }

  Future<ApiResult<T>> getById(String documentId) async {
    final result = await _executor.execute<models.Document>(() {
      return _databases.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );
    });

    if (result.isFailure) {
      return ApiResult.failure(result.requireError);
    }

    final doc = result.requireData;
    final map = _documentToMap(doc);
    return ApiResult.success(fromJson(map));
  }

  Future<ApiResult<T>> create(
    T entity, {
    String? documentId,
    List<String>? permissions,
  }) async {
    final result = await _executor.execute<models.Document>(() {
      return _databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId ?? ID.unique(),
        data: toJson(entity),
        permissions: permissions,
      );
    });

    if (result.isFailure) {
      return ApiResult.failure(result.requireError);
    }

    final doc = result.requireData;
    final map = _documentToMap(doc);
    return ApiResult.success(fromJson(map));
  }

  Future<ApiResult<T>> update(
    String documentId,
    T entity, {
    List<String>? permissions,
  }) async {
    final result = await _executor.execute<models.Document>(() {
      return _databases.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
        data: toJson(entity),
        permissions: permissions,
      );
    });

    if (result.isFailure) {
      return ApiResult.failure(result.requireError);
    }

    final doc = result.requireData;
    final map = _documentToMap(doc);
    return ApiResult.success(fromJson(map));
  }

  Future<ApiResult<void>> delete(String documentId) async {
    final result = await _executor.execute<void>(() {
      return _databases.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );
    });

    if (result.isFailure) {
      return ApiResult.failure(result.requireError);
    }

    return ApiResult<void>.successNoData();
  }
}
