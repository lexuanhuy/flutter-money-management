import '../models/category.dart';

class CategoryService {
  List<Category> getAllCategories() {
    return Category.getDefaultCategories();
  }

  List<Category> getCategoriesByType(TransactionType type) {
    return Category.getDefaultCategories()
        .where((category) => category.type == type)
        .toList();
  }

  Category? getCategoryById(String id) {
    try {
      return Category.getDefaultCategories()
          .firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  Category? getCategoryByName(String name) {
    try {
      return Category.getDefaultCategories()
          .firstWhere((category) => category.name == name);
    } catch (e) {
      return null;
    }
  }
}
