import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventorysystem/models/user.dart';
import 'package:inventorysystem/services/crud.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<UserData> _userDataFromUser(FirebaseUser user) async {
    if (user == null) {
      return null;
    }
    UserData userData = await CrudHelper().getUserDataByUid(user.uid);
    if (userData == null) {
      return UserData(
          uid: user.uid,
          email: user.email,
          verified: user.isEmailVerified,
          targetEmail: user.email);
    }
    return userData;
  }

  Stream<UserData> get user {
    return _firebaseAuth.onAuthStateChanged.asyncMap(_userDataFromUser);
  }

  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      AuthResult result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      FirebaseUser user = result.user;
      return user;
    } catch (error) {
      print(error.toString());
      return null;
    }
  }

  Future register(String email, String password) async {
    try {
      AuthResult result = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      FirebaseUser user = result.user;

      UserData duplicate = await CrudHelper().getUserData('email', user.email);
      if (duplicate != null) {
        print("duplicate email");
        return null;
      }

      UserData userData = UserData(
          uid: user.uid,
          targetEmail: user.email,
          email: user.email,
          verified: user.isEmailVerified,
          roles: Map());

      await CrudHelper().updateUserData(userData);
      return user;
    } catch (error) {
      print(error.toString());
      return null;
    }
  }

  Future signOut() async {
    try {
      return await _firebaseAuth.signOut();
    } catch (error) {
      print(error.toString());
      return null;
    }
  }
}
