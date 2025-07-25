import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:magazine_manager/item_list_view.dart';
import 'l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('itemsBox');
  await Hive.openBox('authBox');
  await Hive.openBox('pendingItemsBox');
  await Hive.openBox('stockBox');

  final authBox = Hive.box('authBox');
  final token = authBox.get('token');

  runApp(MyApp(initialToken: token));
}

class MyApp extends StatefulWidget {
  final Locale? initialLocale;
  final String? initialToken;
  const MyApp({super.key, this.initialLocale, this.initialToken});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  final String apiUrl = 'https://superb-luckily-sunbird.ngrok-free.app';

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    checkOfflineLogin();
  }

  Future<void> checkOfflineLogin() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      final box = Hive.box('itemsBox');
      final token = box.get('access_token');
      if (token != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ItemListView(
              token: token,
              apiUrl: apiUrl,
              isOfflineMode: true,
              isReadOnly: false,
            ),
          ),
        );
      }
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Magazine Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MyHomePage(
        title: AppLocalizations.of(context)?.login ?? 'Login',
        onLocaleChange: setLocale,
        apiUrl: apiUrl,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final String apiUrl;
  final Function(Locale) onLocaleChange;

  const MyHomePage({
    super.key,
    required this.title,
    required this.apiUrl,
    required this.onLocaleChange,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController twoFaController = TextEditingController();

  bool isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('${widget.apiUrl}/api/user/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Email': emailController.text.trim(),
          'Password': passwordController.text,
          'Google2fa': twoFaController.text.trim(),
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        final box = Hive.box('itemsBox');
        await box.put('access_token', token);
        await box.put('email', emailController.text.trim());
        await box.put('password', passwordController.text);
        await box.put('google2fa', twoFaController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.loggedIn ??
                  'Logged in successfully',
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ItemListView(
              token: token,
              apiUrl: widget.apiUrl,
              isOfflineMode: false,
              isReadOnly: false,
            ),
          ),
        );
      } else {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              body['message'] ??
                  AppLocalizations.of(context)?.login ??
                  'Invalid login data',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
      print('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.login),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: (Locale locale) {
              widget.onLocaleChange(locale);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
              PopupMenuItem(value: Locale('en'), child: Text('English')),
              PopupMenuItem(value: Locale('pl'), child: Text('Polski')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: loc.email,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? loc.email : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: loc.password,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? loc.password : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: twoFaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.google2fa,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.security),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return loc.google2fa;
                  if (value.length != 6 || int.tryParse(value) == null) {
                    return 'Kod musi mieć 6 cyfr'; // Możesz też dodać tłumaczenie tego komunikatu
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(loc.login, style: const TextStyle(fontSize: 16)),
                ),
              ),
              SizedBox(height: 12),

              TextButton(
                onPressed: () async {
                  final box = Hive.box('itemsBox');
                  final cachedItems = box.get('items');
                  final cachedToken = box.get('access_token');
                  if (cachedItems != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemListView(
                          token: cachedToken ?? '',
                          apiUrl: widget.apiUrl,
                          isOfflineMode: true,
                          isReadOnly: true,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Brak zapisanych danych magazynu.'),
                      ),
                    );
                  }
                },
                child: Text(
                  loc.checkStockOffline,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
