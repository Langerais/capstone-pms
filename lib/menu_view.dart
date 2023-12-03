import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'dbObjects.dart';

import 'package:flutter/material.dart';
import 'db_helper.dart';  // Replace with your actual path to db_helper.dart

class MenuView extends StatefulWidget {
  @override
  _MenuViewState createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  late Future<List<MenuCategory>> _categories;

  @override
  void initState() {
    super.initState();
    _categories = MenuService.getMenuCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu Categories'),
      ),
      body: FutureBuilder<List<MenuCategory>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No categories available'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                MenuCategory category = snapshot.data![index];
                return ListTile(
                  title: Text(category.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryItemsView(categoryId: category.id),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class CategoryItemsView extends StatelessWidget {
  final int categoryId;

  CategoryItemsView({required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu Items'),
      ),
      body: FutureBuilder<List<MenuItem>>(
        future: MenuService.getMenuItemsByCategory(categoryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No items available in this category'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                MenuItem item = snapshot.data![index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('${item.description}\nPrice: \€${item.price}'),
                  onTap: () {
                    // TODO: Implement item onTap functionality
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
