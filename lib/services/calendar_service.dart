import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DateTime>> fetchLeaveDates() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('holidays')
        .where('status', isEqualTo: true) // Optional filter
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final dateString = data['holidayDate'] ?? '';
      return DateTime.parse(dateString);
    }).toList();
  }



  Future<void> addLeave(DateTime date, String title) async {
    String formattedDate = date.toIso8601String().split('T')[0];
    await _firestore.collection('leaves').add({
      'date': formattedDate,
      'title': title,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> deleteLeave(String docId) async {
    await _firestore.collection('leaves').doc(docId).delete();
  }

  Future<Map<DateTime, List<Map<String, dynamic>>>> getLeaves() async {
    QuerySnapshot snapshot = await _firestore.collection('leaves').get();
    Map<DateTime, List<Map<String, dynamic>>> leaves = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      DateTime date = DateTime.parse(data['date']);
      if (!leaves.containsKey(date)) {
        leaves[date] = [];
      }
      leaves[date]!.add({...data, 'id': doc.id});
    }
    return leaves;
  }
}
