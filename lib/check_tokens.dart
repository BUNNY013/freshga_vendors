import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final users = await FirebaseFirestore.instance.collection('users').get();
  for (var doc in users.docs) {
    print('User: ${doc.id}');
    print('fcmTokens: ${doc.data()['fcmTokens']}');
  }
}
