import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/modules/category/category_controller.dart';
import 'package:simple_live_app/modules/category/category_list_view.dart';

class CategoryPage extends GetView<CategoryController> {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("分类"),
        actions: [
          IconButton(
            onPressed: controller.refreshOrScrollTop,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: CategoryListView(controller.site.id),
    );
  }
}
