import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatelessWidget {
  const WebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) async {
            final uri = Uri.parse(request.url);

            // لو اللينك فيه tel أو mailto أو sms أو whatsapp أو geo
            if (_isExternalScheme(uri)) {
              if (uri.scheme == 'geo' ||
                  request.url.contains('google.com/maps')) {
                await openGoogleMaps(uri);
              } else {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://naya.nawar.site/'));

    return Scaffold(
      body: SafeArea(child: WebViewWidget(controller: controller)),
    );
  }
}

bool _isExternalScheme(Uri uri) {
  const externalSchemes = {'tel', 'mailto', 'sms', 'geo', 'whatsapp', 'maps'};
  return externalSchemes.contains(uri.scheme) ||
      uri.host.contains('google.com');
}

Future<void> openLink(Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) throw 'Could not launch $uri';
}

Future<void> callNumber(String number) =>
    openLink(Uri(scheme: 'tel', path: number));

Future<void> sendEmail(String email, {String? subject, String? body}) {
  return openLink(Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: {
      if (subject != null) 'subject': subject,
      if (body != null) 'body': body,
    },
  ));
}

Future<void> openWebsite(String url) => openLink(Uri.parse(url));

Future<void> openGoogleMaps(Uri uri) async {
  final googleMapsUri = Uri(
    scheme: 'google.navigation',
    queryParameters: {
      'q': uri.path + (uri.query.isNotEmpty ? '?${uri.query}' : '')
    },
  );

  if (!await launchUrl(
    googleMapsUri,
    mode: LaunchMode.externalApplication,
  )) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
