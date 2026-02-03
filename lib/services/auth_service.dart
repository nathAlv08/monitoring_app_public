import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream user changes
  Stream<User?> get user => _auth.authStateChanges();

  // Sign In Email
  Future<UserCredential> signIn({required String email, required String password}) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Sign Up Email
  Future<UserCredential> signUp({required String email, required String password}) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // --- LOGIN GOOGLE (BARU) ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Trigger flow Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User batal login

      // 2. Ambil detail auth dari request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Buat credential baru untuk Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Masuk ke Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Google Sign In Error: $e");
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}