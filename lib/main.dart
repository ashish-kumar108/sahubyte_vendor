import 'package:flutter/material.dart';
import 'package:sahubyte_vendor/repository/auth_session_store.dart';
import 'package:sahubyte_vendor/repository/kyc_gate_repository.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view/home_view.dart';
import 'package:sahubyte_vendor/view/kyc_pending_view.dart';
import 'package:sahubyte_vendor/view/welcome_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SahuByte Vendor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.page,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
          elevation: 0,
          surfaceTintColor: AppColors.surface,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          prefixIconColor: AppColors.primary,
          labelStyle: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        useMaterial3: true,
      ),
      home: const _StartupView(),
    );
  }
}

class _StartupView extends StatelessWidget {
  const _StartupView();

  Future<Widget> _resolveHome() async {
    final session = AuthSessionStore();
    final mobile = await session.getLoggedInMobile();
    final loggedIn = await session.isLoggedIn();
    final pending = await session.hasPendingApproval();
    if (mobile == null || mobile.trim().isEmpty) return const WelcomeView();
    if (!loggedIn && !pending) return const WelcomeView();

    try {
      final kycStatus = await KycGateRepository().getStatusForMobile(mobile);
      if (kycStatus.approved) {
        await session.setLoggedIn(true, mobile: mobile);
        return const HomeView();
      }
      await session.setPendingApproval(mobile: mobile);
      return KycPendingView(mobile: mobile);
    } catch (_) {
      return loggedIn ? const HomeView() : KycPendingView(mobile: mobile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolveHome(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: SkeletonCardList(itemCount: 3),
          );
        }

        return snapshot.data!;
      },
    );
  }
}
