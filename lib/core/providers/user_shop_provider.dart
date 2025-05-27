// ignore_for_file: unused_import

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:survey_camp/core/models/user_shop_model.dart';
import '';

final userShopDataProvider = FutureProvider<ShopData>((ref) async {
  // Assuming you're using Firebase, adjust according to your backend
  final currentUser = FirebaseAuth.instance.currentUser;
  final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .get();

  return ShopData.fromMap(userData.data() ?? {});
});