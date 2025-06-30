import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<bool> verifyUser(String empId, String phoneNumber) async {
    final query = await _db.collection('users')
        .where('empId', isEqualTo: empId)
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  Future<void> updatePassword(String empId, String newPassword) async {
    final query = await _db.collection('users')
        .where('empId', isEqualTo: empId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await _db.collection('users')
          .doc(query.docs.first.id)
          .update({'password': newPassword});
    }
  }
}
