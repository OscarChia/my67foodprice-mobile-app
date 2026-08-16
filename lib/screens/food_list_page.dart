import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FoodListPage extends StatefulWidget {
  const FoodListPage({super.key});

  @override
  State<FoodListPage> createState() => _FoodListPageState();
}

class _FoodListPageState extends State<FoodListPage> {
  List<Map<String, dynamic>> foodItems = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFoodItems();
  }

  Future<void> fetchFoodItems() async {
    try {
      final data = await Supabase.instance.client
          .from('food_items')
          .select()
          .limit(20);

      if (!mounted) {
        return;
      }

      setState(() {
        foodItems = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Prices'),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : foodItems.isEmpty
          ? const Center(
        child: Text('No food items found'),
      )
          : ListView.builder(
        itemCount: foodItems.length,
        itemBuilder: (context, index) {
          final food = foodItems[index];

          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.shopping_basket),
              ),

              title: Text(
                food['item'] ?? 'Unknown Item',
              ),

              subtitle: Text(
                '${food['item_category'] ?? ''} • '
                    '${food['unit'] ?? ''}',
              ),

              trailing: Text(
                '#${food['item_code']}',
              ),
            ),
          );
        },
      ),
    );
  }
}