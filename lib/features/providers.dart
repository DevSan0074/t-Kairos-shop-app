import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- LIVE Home Feed (Stream) ---
final postsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('posts')
      .stream(primaryKey: ['id']) // Listens to changes live
      .order('created_at', ascending: false); // Newest first
});

// --- Market ---
final productsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client
      .from('products')
      .select()
      .order('name', ascending: true);
  return List<Map<String, dynamic>>.from(response);
});

// --- Cart ---
final cartProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser!.id;
  return Supabase.instance.client
      .from('cart_items')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .asyncMap((data) async {
        final List<Map<String, dynamic>> enriched = [];
        for (var item in data) {
          final product = await Supabase.instance.client
              .from('products')
              .select()
              .eq('id', item['product_id'])
              .single();
          enriched.add({...item, 'product': product});
        }
        return enriched;
      });
});
