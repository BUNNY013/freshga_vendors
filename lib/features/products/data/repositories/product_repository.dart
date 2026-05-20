import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/product_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _products => _firestore.collection('products');

  Future<void> createProduct(ProductModel product) async {
    try {
      await _products.doc(product.productId).set(product.toJson());
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _products.doc(product.productId).update(product.toJson());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Stream<List<ProductModel>> getProductsByStore(String storeId) {
    return _products
        .where('storeId', isEqualTo: storeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
