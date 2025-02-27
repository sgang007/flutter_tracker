import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tracker/actions.dart';
import 'package:flutter_tracker/model/message.dart';

abstract class BaseAuthService {
  Future<User> signIn(
    String email,
    String password,
  );

  Future<User> signUp(
    String email,
    String password,
    String displayName,
  );

  Future<User> getCurrentUser();
  Future<void> signOut();
}

class Auth implements BaseAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign In was cancelled');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential result = await _firebaseAuth.signInWithCredential(credential);
    return result.user!;
  }

  Future<User> signIn(
    String email,
    String password,
  ) async {
    final UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user!;
  }

  Future<User> signUp(
    String email,
    String password,
    String displayName,
  ) async {
    final UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await result.user?.updateDisplayName(displayName);
    return result.user!;
  }

  Future<User> getCurrentUser() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No user currently signed in');
    }
    return user;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    return _firebaseAuth.signOut();
  }
}

class AuthService implements BaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  listen() {
    _firebaseAuth.onAuthStateChanged.listen((firebaseUser) {
      // ...
    });
  }

  @override
  Future<FirebaseUser> signIn(
    String email,
    String password,
  ) async {
    AuthResult result = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return result.user;
  }

  @override
  Future<FirebaseUser> signUp(
    String name,
    String email,
    String password, {
    store,
  }) async {
    AuthResult result = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    FirebaseUser user = result.user;

    // Update the displayName in the firebase user record
    if (name != null) {
      UserUpdateInfo userUpdateInfo = UserUpdateInfo();
      userUpdateInfo.displayName = name;

      await user.updateProfile(userUpdateInfo);
      await user.reload();
      user = await _firebaseAuth.currentUser();
    }

    return user;
  }

  @override
  Future<FirebaseUser> getCurrentUser() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user;
  }

  @override
  Future<void> signOut() async {
    return await _firebaseAuth.signOut();
  }

  @override
  Future<void> sendEmailVerification({store}) async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    user.sendEmailVerification();

    if (store != null) {
      store.dispatch(
        SendMessageAction(
          Message(
            message: 'Account verification email sent!',
          ),
        ),
      );
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user.isEmailVerified;
  }

  @override
  Future<void> resetPassword(
    String email, {
    store,
    bottomOffset,
  }) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);

    if (store != null) {
      store.dispatch(
        SendMessageAction(
          Message(
            message: 'Reset password email sent!',
            bottomOffset: bottomOffset,
          ),
        ),
      );
    }
  }
}
