import 'package:appwrite_flutter_starter_kit/config/environment.dart';
import 'package:appwrite_flutter_starter_kit/data/models/todo.dart';
import 'package:appwrite_flutter_starter_kit/data/repository/base_crud_repository.dart';

/// ریپازیتوری اختصاصی برای کالکشن `todos`
class TodosRepository extends BaseCrudRepository<Todo> {
  TodosRepository()
      : super(
    databaseId: Environment.databaseId,
    collectionId: Environment.collectionIdTodos,
    fromJson: Todo.fromJson,
    toJson: (Todo value) => value.toJson(),
  );
}
