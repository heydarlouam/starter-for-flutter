// lib/data/repository/test_strings_repository.dart


import 'package:appwrite_flutter_starter_kit/config/environment.dart';
import 'package:appwrite_flutter_starter_kit/data/models/test_string.dart';
import 'package:appwrite_flutter_starter_kit/data/repository/base_crud_repository.dart';

class TestStringsRepository extends BaseCrudRepository<TestString> {
  TestStringsRepository()
      : super(
    databaseId: Environment.databaseId,
    collectionId: Environment.collectionIdTestStrings,
    fromJson: TestString.fromJson,
    toJson: (TestString value) => value.toJson(),
  );
}
