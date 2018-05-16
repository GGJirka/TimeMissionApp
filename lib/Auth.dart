import 'dart:async' show Future;
import 'dart:io'
    show HttpClient, HttpClientBasicCredentials, HttpClientCredentials;

import 'package:http/http.dart' show BaseClient, IOClient;

typedef Future<bool> HttpAuthenticationCallback(
    Uri uri, String scheme, String realm);

HttpAuthenticationCallback _basicAuthenticationCallback(
    HttpClient client, HttpClientCredentials credentials) =>
        (Uri uri, String scheme, String realm) {
      client.addCredentials(uri, realm, credentials);
      return new Future.value(true);
    };

BaseClient createBasicAuthenticationIoHttpClient(
    String userName, String password) {
  final credentials = new HttpClientBasicCredentials(userName, password);

  final client = new HttpClient();
  client.authenticate = _basicAuthenticationCallback(client, credentials);
  return new IOClient(client);
}