import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_family_sim/core/constants.dart';
import 'package:happy_family_sim/core/router.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:happy_family_sim/features/auth/data/auth_service.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

var logger = Logger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    logger.i("Supabase initialized successfully");
  } catch (e, stackTrace) {
    logger.e("Error during initialization", error: e, stackTrace: stackTrace);
  }

  // initialize dependencies
  final supabase = Supabase.instance.client;
  final authService = AuthService(supabase);
  final authRepository = AuthRepository(authService);

  runApp(HappyFamilyApp(authRepository: authRepository));
}

class HappyFamilyApp extends StatefulWidget {
  final AuthRepository authRepository;
  const HappyFamilyApp({super.key, required this.authRepository});

  @override
  State<HappyFamilyApp> createState() => _HappyFamilyAppState();
}

class _HappyFamilyAppState extends State<HappyFamilyApp> {
  String _currentRole = Constants.guestRole;
  bool _isInitializing = true;
  late StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    // listen to auth changes to update role and log current user
    _authSubscription = widget.authRepository.authStateChanges.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        _updateRole(Constants.guestRole);
      }

      final currUser = data.session?.user.email;
      logger.i('current user: $currUser');
    });

    // on app start, check if there's a persisted role (e.g. from a previous session)
    final persistedRole = await widget.authRepository.getPersistedRole();

    if (mounted) {
      setState(() {
        if (persistedRole != null) {
          _currentRole = persistedRole;
        }
        _isInitializing = false;
      });
    }
  }

  void _updateRole(String newRole) {
    setState(() {
      _currentRole = newRole;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      title: 'Happy Family Sim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: createRouter(
        widget.authRepository,
        _currentRole,
        _updateRole,
      ),
    );
  }
}
