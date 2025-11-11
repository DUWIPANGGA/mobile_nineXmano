import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseRealtimeService {
  // Singleton pattern
  static final FirebaseRealtimeService _instance = FirebaseRealtimeService._internal();
  factory FirebaseRealtimeService() => _instance;
  FirebaseRealtimeService._internal();

  late DatabaseReference _databaseRef;
  bool _isInitialized = false;

  // ========== INITIALIZATION ========== //
  
  /// Initialize Firebase Realtime Database
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDge3TsELZ9DbN08MwmBIvN7AY_8F2Pqhk",
          databaseURL: "https://mano-database-ba7bb-default-rtdb.firebaseio.com/",
          appId: "com.example.iTen", // Ganti dengan App ID Anda
          messagingSenderId: "YOUR_SENDER_ID", // Ganti dengan Sender ID Anda
          projectId: "mano-database-ba7bb",
        ),
      );
      
      _databaseRef = FirebaseDatabase.instance.ref();
      _isInitialized = true;
      print('✅ Firebase Realtime Database Initialized');
    } catch (e) {
      print('❌ Firebase Initialization Error: $e');
      rethrow;
    }
  }

  // Helper method untuk mendapatkan reference
  DatabaseReference _getRef(String path) {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _databaseRef.child(path);
  }

  // ========== CREATE OPERATIONS ========== //

  /// Create data dengan path tertentu
  Future<void> create({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _getRef(path).set(data);
      print('✅ Data created at: $path');
    } catch (e) {
      throw Exception('Create failed: $e');
    }
  }

  /// Create data dengan auto-generated ID
  Future<String> createWithAutoId({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    try {
      final newRef = _getRef(path).push();
      await newRef.set(data);
      print('✅ Data created with ID: ${newRef.key}');
      return newRef.key!;
    } catch (e) {
      throw Exception('Create with auto ID failed: $e');
    }
  }

  /// Create atau update multiple data sekaligus
  Future<void> setMultiple(Map<String, dynamic> dataMap) async {
    try {
      await _databaseRef.update(dataMap);
      print('✅ Multiple data created/updated');
    } catch (e) {
      throw Exception('Set multiple failed: $e');
    }
  }

  // ========== READ OPERATIONS ========== //

  /// Read data sekali baca
  Future<Map<String, dynamic>?> read(String path) async {
    try {
      final snapshot = await _getRef(path).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        print('✅ Data read from: $path');
        return data;
      }
      print('ℹ️ No data found at: $path');
      return null;
    } catch (e) {
      throw Exception('Read failed: $e');
    }
  }

  /// Read semua data di path tertentu
  Future<Map<String, dynamic>> readAll(String path) async {
    try {
      final snapshot = await _getRef(path).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        print('✅ All data read from: $path (${data.length} items)');
        return data;
      }
      print('ℹ️ No data found at: $path');
      return {};
    } catch (e) {
      throw Exception('Read all failed: $e');
    }
  }

  /// Read data dengan query/filter
  Future<Map<String, dynamic>> query({
    required String path,
    String? orderBy,
    dynamic equalTo,
    dynamic startAt,
    dynamic endAt,
    int? limit,
    bool limitToLast = false,
  }) async {
    try {
      Query query = _getRef(path);
      
      if (orderBy != null) {
        if (orderBy == 'key') {
          query = query.orderByKey();
        } else if (orderBy == 'value') {
          query = query.orderByValue();
        } else {
          query = query.orderByChild(orderBy);
        }
      }
      
      if (equalTo != null) query = query.equalTo(equalTo);
      if (startAt != null) query = query.startAt(startAt);
      if (endAt != null) query = query.endAt(endAt);
      if (limit != null) {
        query = limitToLast ? query.limitToLast(limit) : query.limitToFirst(limit);
      }
      
      final snapshot = await query.get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        print('✅ Query result: ${data.length} items');
        return data;
      }
      return {};
    } catch (e) {
      throw Exception('Query failed: $e');
    }
  }

  // ========== UPDATE OPERATIONS ========== //

  /// Update data tertentu (partial update)
  Future<void> update({
    required String path,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _getRef(path).update(updates);
      print('✅ Data updated at: $path');
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  /// Update multiple paths sekaligus
  Future<void> updateMultiple(Map<String, dynamic> updates) async {
    try {
      await _databaseRef.update(updates);
      print('✅ Multiple updates completed');
    } catch (e) {
      throw Exception('Update multiple failed: $e');
    }
  }

  /// Set value (overwrite atau create baru)
  Future<void> set({
    required String path,
    required dynamic value,
  }) async {
    try {
      await _getRef(path).set(value);
      print('✅ Value set at: $path');
    } catch (e) {
      throw Exception('Set failed: $e');
    }
  }

  // ========== DELETE OPERATIONS ========== //

  /// Delete data di path tertentu
  Future<void> delete(String path) async {
    try {
      await _getRef(path).remove();
      print('✅ Data deleted at: $path');
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }

  /// Delete multiple paths sekaligus
  Future<void> deleteMultiple(List<String> paths) async {
    try {
      final updates = <String, dynamic>{};
      for (var path in paths) {
        updates[path] = null;
      }
      await _databaseRef.update(updates);
      print('✅ Multiple deletions completed: ${paths.length} items');
    } catch (e) {
      throw Exception('Delete multiple failed: $e');
    }
  }

  /// Delete field tertentu dari data
  Future<void> deleteField(String path, String field) async {
    try {
      await _getRef(path).child(field).remove();
      print('✅ Field $field deleted from: $path');
    } catch (e) {
      throw Exception('Delete field failed: $e');
    }
  }

  // ========== REAL-TIME STREAM OPERATIONS ========== //

  /// Stream data untuk real-time updates
  Stream<Map<String, dynamic>?> stream(String path) {
    return _getRef(path).onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  /// Stream semua data di path
  Stream<Map<String, dynamic>> streamAll(String path) {
    return _getRef(path).onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {};
    });
  }

  /// Stream data dengan query
  Stream<Map<String, dynamic>> streamQuery({
    required String path,
    String? orderBy,
    dynamic equalTo,
    int? limit,
  }) {
    Query query = _getRef(path);
    
    if (orderBy != null) query = query.orderByChild(orderBy);
    if (equalTo != null) query = query.equalTo(equalTo);
    if (limit != null) query = query.limitToFirst(limit);
    
    return query.onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {};
    });
  }

  /// Stream single value changes
  Stream<dynamic> streamValue(String path) {
    return _getRef(path).onValue.map((event) => event.snapshot.value);
  }

  // ========== UTILITY & HELPER METHODS ========== //

  /// Check if data exists
  Future<bool> exists(String path) async {
    try {
      final snapshot = await _getRef(path).get();
      return snapshot.exists;
    } catch (e) {
      throw Exception('Exists check failed: $e');
    }
  }

  /// Get total count of items
  Future<int> count(String path) async {
    try {
      final snapshot = await _getRef(path).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        return data.length;
      }
      return 0;
    } catch (e) {
      throw Exception('Count failed: $e');
    }
  }

  /// Transaction operation untuk data yang perlu konsistensi
  // Future<void> transaction({
  //   required String path,
  //   required dynamic Function(dynamic current) transactionHandler,
  // }) async {
  //   try {
  //     await _getRef(path).runTransaction((mutableData) {
  //       mutableData.value = transactionHandler(mutableData.value);
  //       return mutableData;
  //     });
  //     print('✅ Transaction completed at: $path');
  //   } catch (e) {
  //     throw Exception('Transaction failed: $e');
  //   }
  // }

  /// Increment numeric value
  Future<void> increment(String path, String field, int value) async {
    try {
      await _getRef(path).child(field).set(ServerValue.increment(value));
      print('✅ Incremented $field by $value at: $path');
    } catch (e) {
      throw Exception('Increment failed: $e');
    }
  }

  /// Decrement numeric value
  Future<void> decrement(String path, String field, int value) async {
    await increment(path, field, -value);
  }

  /// Get database reference untuk operasi custom
  DatabaseReference getRef(String path) {
    return _getRef(path);
  }

  /// Check initialization status
  bool get isInitialized => _isInitialized;
}