import 'package:appwrite_flutter_starter_kit/config/environment.dart';
import 'package:appwrite_flutter_starter_kit/config/network/appwrite_client.dart';
import 'package:appwrite_flutter_starter_kit/page/appwritestarterkit.dart';
import 'package:appwrite_flutter_starter_kit/state/connection_provider.dart';
import 'package:appwrite_flutter_starter_kit/state/test_strings_provider.dart';
import 'package:appwrite_flutter_starter_kit/page/test_strings_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // این‌جا حتماً AppwriteClient را init می‌کنیم
  await AppwriteClient.instance.init(
    endpoint: Environment.appwritePublicEndpoint,
    projectId: Environment.appwriteProjectId,
    // روی وب selfSigned معمولاً لازم نیست
    selfSigned: !kIsWeb,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ConnectionProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TestStringsProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appwrite Playground',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        TestStringsPage.routeName: (context) => const TestStringsPage(),
        '/starter-kit': (context) => const AppwriteStarterKit(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Home'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(TestStringsPage.routeName);
              },
              child: const Text('Open test_strings debug page'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/starter-kit');
              },
              child: const Text('Open Appwrite StarterKit page'),
            ),
          ],
        ),
      ),
    );
  }
}
