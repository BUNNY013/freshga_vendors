import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/products/presentation/providers/product_provider.dart';
import 'features/store/providers/subscription_provider.dart';
import 'features/store/providers/store_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'core/providers/network_provider.dart';
import 'core/providers/maintenance_provider.dart';
import 'core/presentation/screens/no_internet_screen.dart';
import 'core/presentation/screens/maintenance_mode_screen.dart';
import 'core/providers/update_provider.dart';
import 'core/presentation/screens/force_update_screen.dart';
import 'core/presentation/screens/soft_update_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
        ChangeNotifierProvider(create: (_) => UpdateProvider()),
      ],
      child: const FreshGaVendorApp(),
    ),
  );
}

class FreshGaVendorApp extends StatelessWidget {
  const FreshGaVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FreshGa Vendors',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            Consumer3<NetworkProvider, MaintenanceProvider, UpdateProvider>(
              builder: (context, network, maintenance, update, _) {
                if (!network.isOnline) {
                  return Positioned.fill(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: MediaQuery(
                        data: MediaQueryData.fromView(View.of(context)),
                        child: Theme(
                          data: AppTheme.lightTheme,
                          child: const NoInternetScreen(),
                        ),
                      ),
                    ),
                  );
                }
                
                if (update.isForceUpdate) {
                  return Positioned.fill(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: MediaQuery(
                        data: MediaQueryData.fromView(View.of(context)),
                        child: Theme(
                          data: AppTheme.lightTheme,
                          child: const ForceUpdateScreen(),
                        ),
                      ),
                    ),
                  );
                }
                
                if (maintenance.isMaintenanceMode) {
                  return Positioned.fill(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: MediaQuery(
                        data: MediaQueryData.fromView(View.of(context)),
                        child: Theme(
                          data: AppTheme.lightTheme,
                          child: const MaintenanceModeScreen(),
                        ),
                      ),
                    ),
                  );
                }

                if (update.isSoftUpdate) {
                  return Positioned.fill(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: MediaQuery(
                        data: MediaQueryData.fromView(View.of(context)),
                        child: Theme(
                          data: AppTheme.lightTheme,
                          child: const SoftUpdateOverlay(),
                        ),
                      ),
                    ),
                  );
                }
                
                return const SizedBox.shrink();
              },
            ),
          ],
        );
      },
    );
  }
}
