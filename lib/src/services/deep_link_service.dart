import 'dart:async';
import 'dart:developer' as developer;
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  static StreamSubscription? _linkSubscription;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final AppLinks _appLinks = AppLinks();

  static void initialize() {
    try {
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          developer.log('Deep link recibido: $uri', name: 'DeepLinkService');
          _handleIncomingLink(uri.toString());
        },
        onError: (err) {
          developer.log('Error en deep link: $err', name: 'DeepLinkService');
        },
      );
      developer.log('Deep links inicializados correctamente', name: 'DeepLinkService');
    } catch (e) {
      developer.log('Error inicializando deep links: $e', name: 'DeepLinkService');
    }
  }

  static void _handleIncomingLink(String link) {
    final uri = Uri.parse(link);
    
    if (uri.scheme == 'iot' && uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      
      if (token != null && token.isNotEmpty) {
        navigatorKey.currentState?.pushNamed(
          '/reset-password',
          arguments: {'token': token},
        );
      }
    }
  }

  static Future<String?> getInitialLink() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        developer.log('Link inicial encontrado: $initialUri', name: 'DeepLinkService');
        if (initialUri.scheme == 'iot' && initialUri.host == 'reset-password') {
          return initialUri.queryParameters['token'];
        }
      }
    } catch (e) {
      developer.log('Error obteniendo link inicial: $e', name: 'DeepLinkService');
    }
    return null;
  }

  static void dispose() {
    _linkSubscription?.cancel();
  }
}