import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeService {
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('users');

  Stream<QuerySnapshot> getEmployeesStream({required String department}) {
    return usersCollection.snapshots();
  }

  Future<void> addEmployee(Map<String, dynamic> data) async {
    await usersCollection.add(data);
  }

  Future<void> updateEmployee(String id, Map<String, dynamic> data) async {
    await usersCollection.doc(id).update(data);
  }

  Future<void> deleteEmployee(String id) async {
    await usersCollection.doc(id).delete();
  }
}
