// category_page.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../../../core/models/transaction_category_model.dart';
import '../../../core/providers/category_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});
  static const nameRoute = 'categoryPage';

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  CategoryInfo? _selectedCategory;

  void _onCategorySelected(CategoryInfo category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null; // Batalkan pilihan jika chip yang sama ditekan
      } else {
        _selectedCategory = category;
      }
    });
  }

  void _showAddCategoryDialog(CategoryType type) { // Terima tipe kategori yang akan dibuat
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Category',
      barrierColor: Colors.black.withValues(alpha : 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return AddCategoryPopup(categoryType: type); // Kirim tipe ke popup
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  void _showDeleteCategoryDialog(CategoryInfo categoryToDelete) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete Category',
      barrierColor: Colors.black.withValues(alpha : 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return DeleteCategoryPopup(
          category: categoryToDelete,
          onConfirm: () {
            if (mounted) {
              setState(() {
                _selectedCategory = null;
              });
            }
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        // Cek apakah kategori yang dipilih masih ada. Jika tidak, batalkan pilihan.
        if (_selectedCategory != null && !categoryProvider.allAvailableCategories.contains(_selectedCategory)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedCategory = null;
              });
            }
          });
        }
        
        // ✅ DIHAPUS: DefaultTabController tidak lagi digunakan
        return Scaffold(
          backgroundColor: customCream,
          body: Stack(
            children: [
              const GridBackground(gridSize: 50, lineColor: Color.fromARGB(50, 0, 0, 0)),
              SafeArea(
                child: SingleChildScrollView(
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.all(16.0),
                  physics: const ClampingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        // ✅ DIUBAH: crossAxisAlignment agar judul rata kiri
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TopNavigationBar(title: 'Category'),
                          const SizedBox(height: 12),
                          StyledCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Expense Categories',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black),
                                ),
                                const Divider(height: 8),
                                _CategoryListTab(
                                  categoryType: CategoryType.expense,
                                  customCategories: categoryProvider.customExpenseCategories,
                                  defaultCategories: categoryProvider.defaultExpenseCategories,
                                  selectedCategory: _selectedCategory,
                                  onCategorySelected: _onCategorySelected,
                                  onAddCategory: () => _showAddCategoryDialog(CategoryType.expense),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _selectedCategory == null ? 0 : 60,
                            margin: EdgeInsets.only(bottom: _selectedCategory == null ? 0 : 12),
                            child: _selectedCategory == null
                                ? const SizedBox.shrink()
                                : Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: customPink,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE88B8B)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(_selectedCategory!.icon, color: Colors.black),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Selected: ${_selectedCategory!.name}',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (categoryProvider.allCustomCategories.contains(_selectedCategory))
                                          IconButton(
                                            onPressed: () {
                                              if (_selectedCategory != null) {
                                                _showDeleteCategoryDialog(_selectedCategory!);
                                              }
                                            },
                                            icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)),
                                          ),
                                      ],
                                    ),
                                  ),
                          ),
                          StyledCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Income Categories',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black),
                                ),
                                const Divider(height: 8),
                                _CategoryListTab(
                                  categoryType: CategoryType.income,
                                  customCategories: categoryProvider.customIncomeCategories,
                                  defaultCategories: categoryProvider.defaultIncomeCategories,
                                  selectedCategory: _selectedCategory,
                                  onCategorySelected: _onCategorySelected,
                                  onAddCategory: () => _showAddCategoryDialog(CategoryType.income),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class _CategoryListTab extends StatelessWidget {
  final CategoryType categoryType;
  final List<CategoryInfo> customCategories;
  final List<CategoryInfo> defaultCategories;
  final CategoryInfo? selectedCategory;
  final Function(CategoryInfo) onCategorySelected;
  final VoidCallback onAddCategory;

  const _CategoryListTab({
    required this.categoryType,
    required this.customCategories,
    required this.defaultCategories,
    this.selectedCategory,
    required this.onCategorySelected,
    required this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Custom Category', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: onAddCategory,
                ),
              ],
            ),
            customCategories.isEmpty
                ? Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('Press \'+\' to add a new category.')),
                  )
                : Container(
                  padding: EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                      spacing: 12.0,
                      runSpacing: 12.0,
                      children: customCategories.map((category) {
                        return CategoryChip(
                          category: category,
                          isSelected: selectedCategory == category,
                          onSelected: onCategorySelected,
                        );
                      }).toList(),
                    ),
                ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Default Category', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),
            const SizedBox(height: 12),
            CategorySelector(
              categories: defaultCategories,
              selectedCategory: selectedCategory,
              onCategorySelected: onCategorySelected,
            ),
          ],
        ),
      ],
    );
  }
}

class AddCategoryPopup extends StatefulWidget {
  final CategoryType categoryType;
  const AddCategoryPopup({super.key, required this.categoryType});

  @override
  State<AddCategoryPopup> createState() => _AddCategoryPopupState();
}

class _AddCategoryPopupState extends State<AddCategoryPopup> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  IconData? _selectedIcon;
  bool _isSaving = false;
  
  final List<IconData> _iconOptions = [
    Icons.add_shopping_cart, Icons.airplanemode_active, Icons.attach_money,
    Icons.book, Icons.build, Icons.card_giftcard, Icons.celebration,
    Icons.computer, Icons.devices, Icons.directions_bike, Icons.emoji_food_beverage,
    Icons.fastfood, Icons.favorite, Icons.fitness_center, Icons.pets, Icons.phone_android,
  ];

  @override
  void initState() {
    super.initState();
    _selectedIcon = _iconOptions.first;
  }

  Future<void> _submitCategory() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

      final newCategory = CategoryInfo(
        id: '', 
        name: _nameController.text.trim(),
        icon: _selectedIcon!,
        type: widget.categoryType,
      );

      try {
        await context.read<CategoryProvider>().addCustomCategory(newCategory);
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add category: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isSaving = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StyledCard(
            width: 320,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add ${widget.categoryType.name.capitalize()} Category', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Category Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Enter category name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a category name.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Icon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10,
                        ),
                        itemCount: _iconOptions.length,
                        itemBuilder: (context, index) {
                          final icon = _iconOptions[index];
                          final isSelected = _selectedIcon == icon;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedIcon = icon),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected ? customPink : customYellow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.black),
                              ),
                              child: Icon(icon, color: isSelected ? Colors.white : Colors.black, size: 24),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: PrimaryButton(
                      text: _isSaving ? 'Saving...' : 'Add Category', 
                      onPressed: _isSaving ? null : _submitCategory
                    )
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
    String capitalize() {
      return "${this[0].toUpperCase()}${substring(1)}";
    }
}

class DeleteCategoryPopup extends StatefulWidget {
  final CategoryInfo category;
  final VoidCallback onConfirm;

  const DeleteCategoryPopup({
    super.key,
    required this.category,
    required this.onConfirm,
  });

  @override
  State<DeleteCategoryPopup> createState() => _DeleteCategoryPopupState();
}

class _DeleteCategoryPopupState extends State<DeleteCategoryPopup> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    if (_isDeleting) return;
    setState(() { _isDeleting = true; });

    try {
      await context.read<CategoryProvider>().deleteCategory(widget.category.id);
      widget.onConfirm();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete category: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isDeleting = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: StyledCard(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Delete Category', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete "${widget.category.name}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: PrimaryButton(
                        text: _isDeleting ? 'Deleting...' : 'Delete',
                        onPressed: _isDeleting ? null : _handleDelete,
                        color: customRed,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategorySelector extends StatelessWidget {
  final List<CategoryInfo> categories;
  final CategoryInfo? selectedCategory;
  final Function(CategoryInfo) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: categories.map((category) {
        return CategoryChip(
          category: category,
          isSelected: selectedCategory == category,
          onSelected: onCategorySelected,
        );
      }).toList(),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final CategoryInfo category;
  final bool isSelected;
  final Function(CategoryInfo) onSelected;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? customPink : customYellow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: isSelected ? const Offset(2, 2) : const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 20),
            const SizedBox(height: 4),
            Text(
              category.name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}