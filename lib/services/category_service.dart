import '../models/category.dart';

class CategoryService {
  // Get all categories
  List<Category> getAllCategories() {
    return Category.getDefaultCategories();
  }

  // Get categories by type
  List<Category> getCategoriesByType(TransactionType type) {
    return Category.getDefaultCategories()
        .where((category) => category.type == type)
        .toList();
  }

  // Get category by id
  Category? getCategoryById(String id) {
    try {
      return Category.getDefaultCategories()
          .firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
}
