import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams the list of favorite ad IDs for the currently authenticated user.
/// Path: users/{userId}/favourites/{adId}
final favoritesStreamProvider = StreamProvider. autoDispose<List<String>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(<String>[]);
  }

  return FirebaseFirestore.instance
      . collection('users')
      . doc(user.uid)
      . collection('favourites')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => doc.id).toList();
  });
});

/// Provider to check if a specific ad is favorited
final isFavoriteProvider = StreamProvider. family<bool, String>((ref, adId) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream. value(false);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favourites')
      .doc(adId)
      .snapshots()
      .map((doc) => doc.exists);
});

/// Service to manage favorites
class FavoritesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Toggle favorite - add if not exists, remove if exists
  Future<void> toggleFavorite(String adId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final favRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('favourites')
        .doc(adId);

    final doc = await favRef.get();

    if (doc.exists) {
      // Remove from favorites
      await favRef.delete();
    } else {
      // Add to favorites
      await favRef.set({
        'adId': adId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Add to favorites
  Future<void> addFavorite(String adId) async {
    final user = _auth. currentUser;
    if (user == null) throw Exception('User not logged in');

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('favourites')
        . doc(adId)
        .set({
      'adId': adId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove from favorites
  Future<void> removeFavorite(String adId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('favourites')
        .doc(adId)
        .delete();
  }
}

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService();
});