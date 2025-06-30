import 'package:cloud_firestore/cloud_firestore.dart';

class CodeMasterService {
  final CollectionReference codeMasterCollection =
  FirebaseFirestore.instance.collection('code_master');

  Future<void> addCodeMaster(Map<String, dynamic> data) async {
    await codeMasterCollection.add(data);
  }

  Future<void> updateCodeMaster(String docId, Map<String, dynamic> data) async {
    await codeMasterCollection.doc(docId).update(data);
  }

  Future<void> deleteCodeMaster(String docId) async {
    await codeMasterCollection.doc(docId).delete();
  }

  Stream<QuerySnapshot> getCodeMasters() {
    return codeMasterCollection.orderBy('createdOn', descending: true).snapshots();
  }
}
