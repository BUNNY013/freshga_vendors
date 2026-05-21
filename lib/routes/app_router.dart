import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/phone_login_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/onboarding/presentation/screens/welcome_intro_screen.dart';
import '../features/onboarding/presentation/screens/verification_pending_screen.dart';
import '../features/onboarding/presentation/screens/rejection_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/store/presentation/screens/store_setup_screen.dart';
import '../features/products/presentation/screens/add_product_screen.dart';
import '../features/store/presentation/screens/edit_store_screen.dart';
import '../data/models/product_model.dart';

import '../features/onboarding/presentation/screens/step1_basic_details_screen.dart';
import '../features/onboarding/presentation/screens/step2_business_info_screen.dart';
import '../features/onboarding/presentation/screens/step3_address_details_screen.dart';
import '../features/onboarding/presentation/screens/step4_legal_documents_screen.dart';
import '../features/onboarding/presentation/screens/step5_bank_details_screen.dart';
import '../features/onboarding/presentation/screens/step6_review_submit_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String?;
          return OtpScreen(phone: phone ?? '');
        },
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeIntroScreen(),
      ),
      GoRoute(
        path: '/onboarding/step1',
        builder: (context, state) => const Step1BasicDetailsScreen(),
      ),
      GoRoute(
        path: '/onboarding/step2',
        builder: (context, state) => const Step2BusinessInfoScreen(),
      ),
      GoRoute(
        path: '/onboarding/step3',
        builder: (context, state) => const Step3AddressDetailsScreen(),
      ),
      GoRoute(
        path: '/onboarding/step4',
        builder: (context, state) => const Step4LegalDocumentsScreen(),
      ),
      GoRoute(
        path: '/onboarding/step5',
        builder: (context, state) => const Step5BankDetailsScreen(),
      ),
      GoRoute(
        path: '/onboarding/step6',
        builder: (context, state) => const Step6ReviewSubmitScreen(),
      ),
      GoRoute(
        path: '/pending',
        builder: (context, state) => const VerificationPendingScreen(),
      ),
      GoRoute(
        path: '/rejected',
        builder: (context, state) => const RejectionScreen(),
      ),
      GoRoute(
        path: '/store-setup',
        builder: (context, state) => const StoreSetupScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/add-product',
        builder: (context, state) {
          final product = state.extra as ProductModel?;
          return AddProductScreen(product: product);
        },
      ),
      GoRoute(
        path: '/edit-store',
        builder: (context, state) => const EditStoreScreen(),
      ),
    ],
    redirect: (context, state) {
      // We will handle most redirections inside SplashScreen or AuthListener
      // to avoid complex GoRouter redirect loops.
      return null;
    },
  );
}
