import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../providers.dart';
import 'package:intl/intl.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("My Cart")),
      body: cartAsync.when(
        data: (cartItems) {
          if (cartItems.isEmpty)
            return const Center(child: Text("Cart is empty 🌸"));

          double total = 0;
          for (var item in cartItems) {
            total += (item['product']['price'] * item['quantity']);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final product = item['product'];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: product['image_url'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(product['name']),
                      subtitle: Text("Qty: ${item['quantity']}"),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () async {
                          await Supabase.instance.client
                              .from('cart_items')
                              .delete()
                              .eq('id', item['id']);
                        },
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total: ${NumberFormat.currency(symbol: '\$').format(total)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text("Checkout"),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        error: (e, s) => Center(child: Text("Error: $e")),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
