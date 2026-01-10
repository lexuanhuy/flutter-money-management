import 'package:flutter/material.dart';
import '../models/category.dart';

class CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final Function(Category) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = selectedCategory?.id == category.id;

        return GestureDetector(
          onTap: () => onCategorySelected(category),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? category.color.withOpacity(0.2)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? category.color : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.icon,
                  color: category.color,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? category.color : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
