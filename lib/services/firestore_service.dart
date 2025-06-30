import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<Map<String, dynamic>?> loginWithEmailAndPassword(String email, String password) async {
//     try {
//       print("🔐 Attempting login for: $email");
//
//       // Query user by email
//       final querySnapshot = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .limit(1)
//           .get();
//
//       if (querySnapshot.docs.isNotEmpty) {
//         final userDoc = querySnapshot.docs.first;
//         final data = userDoc.data();
//
//         // Check if password matches
//         if (data.containsKey('password') && data['password'] == password) {
//           print("✅ Login successful for: $email");
//           return data;
//         } else {
//           print("Password mismatch or data missing");
//         }
//       } else {
//         print("No user found with email: $email");
//       }
//     } catch (e) {
//       print("❌ Error during login: $e");
//     }
//
//     print("❌ Login failed - incorrect credentials");
//     return null;
//   }
// }
  Future<Map<String, dynamic>?> loginWithEmailAndPassword(String email, String password) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        final userData = userDoc.data();
        final docId = userDoc.id;

        // 🔹 If HR, mark loggedin = true
        if (userData['role'].toString().toLowerCase() == 'hr') {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(docId)
              .update({'loggedin': true});
        }

        return {
          ...userData,
          'uid': docId,
        };
      } else {
        return null;
      }
    } catch (e) {
      print("Login error in FirestoreService: $e");
      return null;
    }
  }

  getAttendanceByDate(String formattedDate  ) {}

}
