import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/sale.dart';
import 'pos_repository.dart';

class HttpPosRepository implements PosRepository {
  HttpPosRepository({
    required String baseUrl,
    String? apiKey,
    http.Client? client,
  })  : _baseUri = Uri.parse(baseUrl.replaceAll(RegExp(r'/+$'), '')),
        _apiKey = apiKey,
        _client = client ?? http.Client();

  final Uri _baseUri;
  final String? _apiKey;
  final http.Client _client;

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        if (_apiKey != null && _apiKey!.isNotEmpty) 'x-api-key': _apiKey!,
      };

  @override
  Future<PosSnapshot> load() async {
    final productsBody = await _getJson('/api/products');
    final salesBody = await _getJson(
      '/api/sales',
      queryParameters: {'pageSize': '50'},
    );

    return PosSnapshot(
      products: _dataList(productsBody)
          .map((item) => Product.fromJson(_jsonMap(item)))
          .toList(),
      sales: _dataList(salesBody)
          .map((item) => Sale.fromJson(_jsonMap(item)))
          .toList(),
    );
  }

  @override
  Future<Product> createProduct(Product product) async {
    final body = await _sendJson(
      'POST',
      '/api/products',
      product.toJson(),
      expectedStatus: 201,
    );
    return Product.fromJson(_jsonMap(body['data']));
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final body = await _sendJson(
      'PATCH',
      '/api/products/${Uri.encodeComponent(product.id)}',
      product.toJson(),
    );
    return Product.fromJson(_jsonMap(body['data']));
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _send(
      'DELETE',
      '/api/products/${Uri.encodeComponent(id)}',
      expectedStatus: 204,
    );
  }

  @override
  Future<void> clearSales() async {
    await _send('DELETE', '/api/sales', expectedStatus: 204);
  }

  @override
  Future<CheckoutCommit> commitCheckout({
    required List<Product> products,
    required List<Sale> sales,
    required Sale sale,
  }) async {
    final body = await _sendJson(
      'POST',
      '/api/checkout',
      {
        'items': sale.items
            .map((item) => {
                  'productId': item.productId,
                  'qty': item.qty,
                })
            .toList(),
        'cash': sale.cash,
      },
      expectedStatus: 201,
    );

    final data = _jsonMap(body['data']);
    final committedSale = Sale.fromJson(_jsonMap(data['sale'] ?? data));
    final hasSnapshot =
        data.containsKey('products') && data.containsKey('sales');

    return CheckoutCommit(
      sale: committedSale,
      snapshot: hasSnapshot
          ? PosSnapshot(
              products: _list(data['products'])
                  .map((item) => Product.fromJson(_jsonMap(item)))
                  .toList(),
              sales: _list(data['sales'])
                  .map((item) => Sale.fromJson(_jsonMap(item)))
                  .toList(),
            )
          : null,
    );
  }

  Uri _uri(String path, {Map<String, String>? queryParameters}) =>
      _baseUri.replace(
        path: '${_baseUri.path}${path.startsWith('/') ? path : '/$path'}',
        queryParameters: queryParameters,
      );

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _client.get(
      _uri(path, queryParameters: queryParameters),
      headers: _headers,
    );
    return _decodeResponse(response, expectedStatus: 200);
  }

  Future<Map<String, dynamic>> _sendJson(
    String method,
    String path,
    Object body, {
    int expectedStatus = 200,
  }) async {
    final response = await _send(
      method,
      path,
      body: jsonEncode(body),
      expectedStatus: expectedStatus,
    );
    if (response.body.isEmpty) return const {};
    return _decodeResponse(response, expectedStatus: expectedStatus);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    String? body,
    required int expectedStatus,
  }) async {
    final uri = _uri(path);
    final response = switch (method) {
      'POST' => await _client.post(uri, headers: _headers, body: body),
      'PATCH' => await _client.patch(uri, headers: _headers, body: body),
      'DELETE' => await _client.delete(uri, headers: _headers),
      _ => throw ArgumentError.value(method, 'method'),
    };

    if (response.statusCode != expectedStatus) {
      _throwRepositoryError(response);
    }
    return response;
  }

  Map<String, dynamic> _decodeResponse(
    http.Response response, {
    required int expectedStatus,
  }) {
    if (response.statusCode != expectedStatus) {
      _throwRepositoryError(response);
    }
    final decoded = jsonDecode(response.body);
    return _jsonMap(decoded);
  }

  Never _throwRepositoryError(http.Response response) {
    try {
      final decoded = _jsonMap(jsonDecode(response.body));
      final error = _jsonMap(decoded['error']);
      final message = error['message'];
      if (message is String && message.isNotEmpty) {
        throw PosRepositoryException(message);
      }
    } catch (error) {
      if (error is PosRepositoryException) rethrow;
    }
    throw PosRepositoryException(
      'Server request failed with status ${response.statusCode}.',
    );
  }

  List<dynamic> _dataList(Map<String, dynamic> body) => _list(body['data']);

  List<dynamic> _list(Object? value) {
    if (value is List) return value;
    throw const FormatException('Expected a JSON list.');
  }

  Map<String, dynamic> _jsonMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Expected a JSON object.');
  }
}
