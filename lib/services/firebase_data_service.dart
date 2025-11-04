import 'dart:convert';
import 'package:dio/dio.dart';

  enum FirebaseNode {
    BZL,
    SYSTEM,
    SYSTEMBZL,
    USER
  }
class FirebaseDataService {
  static final FirebaseDataService _instance = FirebaseDataService._internal();
  factory FirebaseDataService() => _instance;
  FirebaseDataService._internal();

  static const String _databaseURL = "https://mano-database-ba7bb-default-rtdb.firebaseio.com/";
  
  late Dio _dio;


  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _databaseURL,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Interceptor untuk logging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🔥 Firebase Request: ${options.method} ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ Firebase Response: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print('❌ Firebase Error: ${e.message}');
        return handler.next(e);
      },
    ));
  }

  // Helper method untuk mendapatkan path node
  String _getNodePath(FirebaseNode node, [String? subPath]) {
    final nodePath = node.name.toLowerCase();
    if (subPath != null && subPath.isNotEmpty) {
      return '$nodePath/$subPath';
    }
    return nodePath;
  }

  // ============ CRUD OPERATIONS ============

  // GET semua data dari node
  Future<Map<String, dynamic>?> getAllData(FirebaseNode node) async {
    try {
      final path = _getNodePath(node);
      final response = await _dio.get('$path.json');
      
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } on DioException catch (e) {
      print('Error getting all data from ${node.name}: $e');
      throw _handleError(e);
    }
  }

  // GET data spesifik dari node dengan sub-path
  Future<dynamic> getData(FirebaseNode node, String subPath) async {
    try {
      final path = _getNodePath(node, subPath);
      final response = await _dio.get('$path.json');
      
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } on DioException catch (e) {
      print('Error getting data from ${node.name}/$subPath: $e');
      throw _handleError(e);
    }
  }

  // POST data ke node (auto-generate ID)
  Future<String?> createData(FirebaseNode node, Map<String, dynamic> data, {String? subPath}) async {
    try {
      final path = _getNodePath(node, subPath);
      final response = await _dio.post(
        '$path.json',
        data: jsonEncode(data),
      );
      
      if (response.statusCode == 200) {
        return response.data['name']; // Return generated ID
      }
      return null;
    } on DioException catch (e) {
      print('Error creating data in ${node.name}: $e');
      throw _handleError(e);
    }
  }

  // PUT data (replace seluruh data di path)
  Future<bool> updateData(FirebaseNode node, String subPath, Map<String, dynamic> data) async {
    try {
      final path = _getNodePath(node, subPath);
      final response = await _dio.put(
        '$path.json',
        data: jsonEncode(data),
      );
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error updating data in ${node.name}/$subPath: $e');
      throw _handleError(e);
    }
  }

  // PATCH data (update sebagian field)
  Future<bool> patchData(FirebaseNode node, String subPath, Map<String, dynamic> data) async {
    try {
      final path = _getNodePath(node, subPath);
      final response = await _dio.patch(
        '$path.json',
        data: jsonEncode(data),
      );
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error patching data in ${node.name}/$subPath: $e');
      throw _handleError(e);
    }
  }

  // DELETE data
  Future<bool> deleteData(FirebaseNode node, String subPath) async {
    try {
      final path = _getNodePath(node, subPath);
      final response = await _dio.delete('$path.json');
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error deleting data from ${node.name}/$subPath: $e');
      throw _handleError(e);
    }
  }

  // DELETE seluruh node (hati-hati!)
  Future<bool> deleteNode(FirebaseNode node) async {
    try {
      final path = _getNodePath(node);
      final response = await _dio.delete('$path.json');
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error deleting node ${node.name}: $e');
      throw _handleError(e);
    }
  }

  // ============ QUERY OPERATIONS ============

  // Query data dengan filter
  Future<Map<String, dynamic>?> queryData(
    FirebaseNode node, {
    Map<String, dynamic>? queryParams,
    String? orderBy,
    bool? equalTo,
    int? limitToFirst,
    int? limitToLast,
  }) async {
    try {
      final parameters = <String, dynamic>{};
      
      if (orderBy != null) parameters['orderBy'] = '"$orderBy"';
      if (equalTo != null) parameters['equalTo'] = equalTo;
      if (limitToFirst != null) parameters['limitToFirst'] = limitToFirst;
      if (limitToLast != null) parameters['limitToLast'] = limitToLast;
      
      final path = _getNodePath(node);
      final response = await _dio.get(
        '$path.json',
        queryParameters: parameters.isNotEmpty ? parameters : null,
      );
      
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } on DioException catch (e) {
      print('Error querying data from ${node.name}: $e');
      throw _handleError(e);
    }
  }

  // ============ BATCH OPERATIONS ============

  // Multiple updates dalam satu request
  Future<bool> batchUpdate(Map<String, dynamic> updates) async {
    try {
      final response = await _dio.patch(
        '.json',
        data: jsonEncode(updates),
      );
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error in batch update: $e');
      throw _handleError(e);
    }
  }

  // ============ SPECIFIC NODE METHODS ============

  // Methods khusus untuk USER node
  Future<Map<String, dynamic>?> getAllUsers() => getAllData(FirebaseNode.USER);
  Future<dynamic> getUser(String userId) => getData(FirebaseNode.USER, userId);
  Future<bool> updateUser(String userId, Map<String, dynamic> userData) => 
      updateData(FirebaseNode.USER, userId, userData);
  Future<bool> deleteUser(String userId) => deleteData(FirebaseNode.USER, userId);

  // Methods khusus untuk BZL node
  Future<Map<String, dynamic>?> getAllBzlData() => getAllData(FirebaseNode.BZL);
  Future<dynamic> getBzlItem(String itemId) => getData(FirebaseNode.BZL, itemId);

  // Methods khusus untuk SYSTEM node
  Future<Map<String, dynamic>?> getSystemData() => getAllData(FirebaseNode.SYSTEM);
  Future<dynamic> getSystemConfig(String configKey) => getData(FirebaseNode.SYSTEM, configKey);

  // Methods khusus untuk SYSTEMBZL node
  Future<Map<String, dynamic>?> getSystemBzlData() => getAllData(FirebaseNode.SYSTEMBZL);
  Future<dynamic> getSystemBzlItem(String itemId) => getData(FirebaseNode.SYSTEMBZL, itemId);

  // ============ UTILITY METHODS ============

  // Check jika data exists
  Future<bool> exists(FirebaseNode node, String subPath) async {
    try {
      final data = await getData(node, subPath);
      return data != null;
    } catch (e) {
      return false;
    }
  }

  // Get data count dalam node
  Future<int> getCount(FirebaseNode node) async {
    try {
      final data = await getAllData(node);
      return data?.length ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Error handling
  String _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final errorData = error.response!.data;
      
      switch (statusCode) {
        case 400:
          return 'Bad Request: $errorData';
        case 401:
          return 'Unauthorized';
        case 403:
          return 'Forbidden';
        case 404:
          return 'Data not found';
        case 500:
          return 'Internal Server Error: $errorData';
        default:
          return 'Error $statusCode: $errorData';
      }
    } else {
      return 'Network error: ${error.message}';
    }
  }

  // Cleanup
  void dispose() {
    _dio.close();
  }
}