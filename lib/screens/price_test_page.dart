import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PriceTestPage extends StatefulWidget {
  const PriceTestPage({super.key});

  @override
  State<PriceTestPage> createState() => _PriceTestPageState();
}

class _PriceTestPageState extends State<PriceTestPage> {
  List<Map<String, dynamic>> prices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPrices();
  }

  Future<void> fetchPrices() async {
    try {
      final data = await Supabase.instance.client
          .from('food_prices')
          .select()
          .limit(20);

      if (!mounted) {
        return;
      }

      setState(() {
        prices = List<Map<String, dynamic>>.from(data);
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
        title: const Text('Price Test'),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : prices.isEmpty
          ? const Center(
        child: Text('No price data found'),
      )
          : ListView.builder(
        itemCount: prices.length,
        itemBuilder: (context, index) {
          final price = prices[index];

          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.attach_money),
              ),
              title: Text(
                'RM ${price['price']}',
              ),
              subtitle: Text(
                'Date: ${price['date']}\n'
                    'Item Code: ${price['item_code']}\n'
                    'Premise Code: ${price['premise_code']}',
              ),
            ),
          );
        },
      ),
    );
  }
}