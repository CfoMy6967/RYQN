import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/services/app_data.dart';
import 'features/dashboard/main_shell.dart';
import 'shared/theme/brand_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('th_TH', null);
  await initializeDateFormatting('th', null);

  final appData = await AppData.load();

  runApp(FinanceApp(appData: appData));
}

class FinanceApp extends StatelessWidget {
  final AppData appData;
  const FinanceApp({super.key, required this.appData});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppData>.value(
      value: appData,
      child: MaterialApp(
        title: 'บัญชีรายรับรายจ่าย',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.light(
            primary: BrandColors.primary,
            onPrimary: BrandColors.onPrimary,
            primaryContainer: BrandColors.primaryContainer,
            onPrimaryContainer: BrandColors.onPrimaryContainer,
            secondary: BrandColors.secondary,
            onSecondary: BrandColors.onSecondary,
            secondaryContainer: BrandColors.secondaryContainer,
            onSecondaryContainer: BrandColors.onSecondaryContainer,
            tertiary: BrandColors.tertiary,
            onTertiary: BrandColors.onTertiary,
            tertiaryContainer: BrandColors.tertiaryContainer,
            onTertiaryContainer: BrandColors.onTertiaryContainer,
            surface: BrandColors.surface,
            onSurface: BrandColors.onSurface,
            surfaceContainerHighest: BrandColors.surfaceContainerHighest,
            outline: BrandColors.outline,
            outlineVariant: BrandColors.outlineVariant,
            error: BrandColors.error,
            onError: BrandColors.onError,
          ),
          scaffoldBackgroundColor: BrandColors.surface,
          appBarTheme: const AppBarTheme(
            backgroundColor: BrandColors.surface,
            foregroundColor: BrandColors.onSurface,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: BrandColors.outlineVariant),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: BrandColors.primary,
            unselectedItemColor: Color(0xFFB0A28E),
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
          ),
          textTheme: GoogleFonts.notoSansThaiTextTheme(),
        ),
        home: const MainShell(),
      ),
    );
  }
}
