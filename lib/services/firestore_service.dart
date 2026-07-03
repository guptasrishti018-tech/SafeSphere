import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save User Profile
  Future<void> saveUser(UserModel user) async {
    await _firestore.collection("users").doc(user.uid).set(user.toMap());
  }

  /// Get Current User Profile
  Future<UserModel?> getCurrentUser() async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) return null;

    final doc = await _firestore.collection("users").doc(uid).get();

    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!);
  }

  /// Check Profile Completed
  Future<bool> isProfileCompleted() async {
    final user = await getCurrentUser();

    if (user == null) return false;

    return user.profileCompleted;
  }

  /// Update Profile
  Future<void> updateUser(Map<String, dynamic> data) async {
    final uid = _auth.currentUser!.uid;

    await _firestore.collection("users").doc(uid).update(data);
  }
}
