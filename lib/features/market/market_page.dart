import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/loading_indicator.dart';
import '../providers.dart';
import 'package:intl/intl.dart';

class MarketPage extends ConsumerWidget {
  const MarketPage({super.key});

  Future<void> _addToCart(BuildContext context, int productId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client.from('cart_items').insert({
      'user_id': userId,
      'product_id': productId,
      'quantity': 1,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Added to cart!"),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Market")),
      body: products.when(
        data: (data) => GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final product = data[index];
            final price = NumberFormat.currency(
              symbol: '\$',
            ).format(product['price']);

            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: product['image_url'] ?? '',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          price,
                          style: const TextStyle(color: AppColors.primary),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: double.infinity,
                          height: 30,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => _addToCart(context, product['id']),
                            child: const Text(
                              "Add",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        error: (e, st) => Center(child: Text("Error loading market")),
        loading: () => const SakuraLoading(),
      ),
    );
  }
}
