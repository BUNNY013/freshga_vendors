import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/store_model.dart';

class StoreRepository {
  final FirebaseFirestore _firestore;

  StoreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _stores => _firestore.collection('stores');

  Future<void> createStore(StoreModel store) async {
    try {
      await _stores.doc(store.storeId).set(store.toJson());
    } catch (e) {
      throw Exception('Failed to create store: $e');
    }
  }

  Future<StoreModel?> getStore(String storeId) async {
    try {
      final doc = await _stores.doc(storeId).get();
      if (doc.exists && doc.data() != null) {
        return StoreModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get store: $e');
    }
  }

  Future<void> updateStore(StoreModel store) async {
    try {
      await _stores.doc(store.storeId).update(store.toJson());
    } catch (e) {
      throw Exception('Failed to update store: $e');
    }
  }
}
