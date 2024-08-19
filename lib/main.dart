import 'dart:developer';

import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AAD OAuth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'AAD OAuth Home'),
      navigatorKey: navigatorKey,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const tenantName = 'rmsvc';
  static const tenantBaseUrl = 'https://$tenantName.b2clogin.com';
  static const policyName = 'B2C_1_RMSVC';
  static const clientId = 'bcc3bf7a-a732-4750-a444-468986574241';
  //TODO: add tenant ID and test
  static const String tenantID = '';

  static final Config config = Config(
    isB2C: false,
    tenant: tenantID,
    policy: policyName,
    clientId: clientId,
    scope: 'profile openid',
    navigatorKey: navigatorKey,
    loader: const SizedBox(),
    appBar: AppBar(
      title: const Text('AAD OAuth Demo'),
    ),
    onPageFinished: (String url) {
      log('onPageFinished: $url');
    },
  );
  final AadOAuth oauth = AadOAuth(config);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text(
              'AzureAD OAuth',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.launch),
            title: const Text('Login${kIsWeb ? ' (web popup)' : ''}'),
            onTap: () async {
              await login(false);
            },
          ),
          if (kIsWeb)
            ListTile(
              leading: const Icon(Icons.launch),
              title: const Text('Login (web redirect)'),
              onTap: () async {
                await login(true);
              },
            ),
          ListTile(
            leading: const Icon(Icons.data_array),
            title: const Text('HasCachedAccountInformation'),
            onTap: () async => hasCachedAccountInformation(),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await logout();
            },
          ),
        ],
      ),
    );
  }

  Future<void> showError(dynamic ex) async {
    await showMessage(ex.toString());
  }

  Future<void> showMessage(String text) async {
    var alert = AlertDialog(content: Text(text), actions: <Widget>[
      TextButton(
          child: const Text('Ok'),
          onPressed: () {
            Navigator.pop(context);
          })
    ]);
    await showDialog(
        context: context, builder: (BuildContext context) => alert);
  }

  Future<void> login(bool redirect) async {
    config.webUseRedirect = redirect;
    final result = await oauth.login();
    result.fold(
      (error) async => await showError(error.toString()),
      (token) async => await showMessage(
          'Logged in successfully, your access token: $token'),
    );
    String? accessToken = await oauth.getAccessToken();
    log('Access token: $accessToken');
    if (accessToken != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(accessToken)));
      }
    }
  }

  Future<void> hasCachedAccountInformation() async {
    bool hasCachedAccountInformation = await oauth.hasCachedAccountInformation;
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Has Cached Account Information: $hasCachedAccountInformation'),
        ),
      );
    }
  }

  Future<void> logout() async {
    await oauth.logout();
    await showMessage('Logged out');
  }
}
