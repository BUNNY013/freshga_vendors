import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/phone_login_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/onboarding/presentation/screens/welcome_intro_screen.dart';
import '../features/onboarding/presentation/screens/verification_pending_screen.dart';
import '../features/onboarding/presentation/screens/rejection_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/store/presentation/screens/store_setup_screen.dart';
import '../features/store/presentation/screens/trial_activation_screen.dart';
import '../features/store/presentation/screens/subscription_dashboard_screen.dart';
import '../features/products/presentation/screens/add_product_screen.dart';
import '../features/products/presentation/screens/edit_product_screen.dart';
import '../features/products/presentation/screens/edit_pricing_screen.dart';
import '../features/products/presentation/screens/edit_product_info_screen.dart';
import '../features/products/presentation/screens/edit_photos_screen.dart';
import '../features/products/presentation/screens/edit_collections_screen.dart';
import '../features/products/presentation/screens/edit_optional_details_screen.dart';
import '../features/products/presentation/screens/under_review_details_screen.dart';
import '../features/products/presentation/screens/changes_required_details_screen.dart';
import '../features/store/presentation/screens/edit_store_screen.dart';
import '../features/store/presentation/screens/editors/store_address_screen.dart';
import '../features/store/presentation/screens/editors/banking_details_screen.dart';
import '../features/store/presentation/screens/editors/store_appearance_screen.dart';
import '../features/store/presentation/screens/editors/store_info_screen.dart';
import '../features/store/presentation/screens/editors/business_details_screen.dart';
import '../features/store/presentation/screens/editors/order_fulfillment_screen.dart';
import '../features/store/presentation/screens/editors/store_categories_screen.dart';
import '../features/store/presentation/screens/editors/policies_screen.dart';
import '../features/store/presentation/screens/editors/faq_screen.dart';
import '../features/store/presentation/screens/editors/social_links_screen.dart';
import '../features/store/presentation/screens/preview/store_preview_screen.dart';
import '../data/models/product_model.dart';
import '../data/models/store_model.dart';

import '../features/analytics/presentation/screens/revenue_analytics_screen.dart';
import '../features/analytics/presentation/screens/orders_analytics_screen.dart';
import '../features/analytics/presentation/screens/products_analytics_screen.dart';
import '../features/analytics/presentation/screens/followers_analytics_screen.dart';
import '../features/analytics/presentation/screens/ratings_analytics_screen.dart';

import '../features/analytics/presentation/screens/earnings_payouts_screen.dart';
import '../features/profile/presentation/screens/customer_feedback_screen.dart';
import '../features/profile/presentation/screens/payouts_screen.dart';
import '../features/profile/presentation/screens/vendor_help_support_screen.dart';
import '../features/profile/presentation/screens/vendor_accounts_screen.dart';
import '../features/onboarding/presentation/screens/step1_basic_details_screen.dart';
import '../features/onboarding/presentation/screens/step2_business_info_screen.dart';
import '../features/onboarding/presentation/screens/step3_address_details_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';

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
        builder: (context, state) => const Step3AddressDetailsScreen(), // Actually Bank Details now
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
        path: '/trial-activation',
        builder: (context, state) => const TrialActivationScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return DashboardScreen(
              initialIndex: extra['initialIndex'] as int? ?? 0,
              ordersInitialIndex: extra['ordersInitialIndex'] as int? ?? 0,
              productsInitialFilter: extra['productsInitialFilter'] as String? ?? 'Live',
            );
          }
          final initialIndex = extra as int? ?? 0;
          return DashboardScreen(initialIndex: initialIndex);
        },
      ),
      GoRoute(
        path: '/add-product',
        builder: (context, state) {
          final product = state.extra as ProductModel?;
          return AddProductScreen(product: product);
        },
      ),
      GoRoute(
        path: '/edit-product',
        builder: (context, state) {
          final product = state.extra as ProductModel;
          return EditProductScreen(product: product);
        },
      ),
      GoRoute(
        path: '/edit-pricing',
        builder: (context, state) {
          final product = state.extra as ProductModel;
          return EditPricingScreen(product: product);
        },
      ),
      GoRoute(
        path: '/edit-photos',
        builder: (context, state) {
          final product = state.extra as ProductModel;
          return EditPhotosScreen(product: product);
        },
      ),
      GoRoute(
        path: '/edit-collections',
        builder: (context, state) {
          final product = state.extra as ProductModel;
          return EditCollectionsScreen(product: product);
        },
      ),
      GoRoute(
        path: '/edit-optional-details',
        builder: (context, state) {
          final product = state.extra as ProductModel;
          return EditOptionalDetailsScreen(product: product);
        },
      ),
      GoRoute(
        path: '/edit-product-info',
        builder: (context, state) {
          final product = state.extra as ProductModel;
          return EditProductInfoScreen(product: product);
        },
      ),
      GoRoute(
        path: '/under-review-details',
        builder: (context, state) {
          final product = state.extra as ProductModel;
          return UnderReviewDetailsScreen(product: product);
        },
      ),
      GoRoute(
        path: '/changes-required-details',
        builder: (context, state) {
          final product = state.extra as ProductModel;
          return ChangesRequiredDetailsScreen(product: product);
        },
      ),
      GoRoute(
        path: '/edit-store',
        builder: (context, state) => const EditStoreScreen(),
      ),
      GoRoute(
        path: '/store/address',
        builder: (context, state) => const StoreAddressScreen(),
      ),
      GoRoute(
        path: '/store/banking',
        builder: (context, state) => const BankingDetailsScreen(),
      ),
      GoRoute(
        path: '/store/appearance',
        builder: (context, state) => const StoreAppearanceScreen(),
      ),
      GoRoute(
        path: '/store/info',
        builder: (context, state) => const StoreInfoScreen(),
      ),
      GoRoute(
        path: '/store/business-details',
        builder: (context, state) => const BusinessDetailsScreen(),
      ),
      GoRoute(
        path: '/store/order-fulfillment',
        builder: (context, state) => const OrderFulfillmentScreen(),
      ),
      GoRoute(
        path: '/store/categories',
        builder: (context, state) => const StoreCategoriesScreen(),
      ),
      GoRoute(
        path: '/store/policies',
        builder: (context, state) => const PoliciesScreen(),
      ),
      GoRoute(
        path: '/store/faq',
        builder: (context, state) => const FAQScreen(),
      ),
      GoRoute(
        path: '/store/social-links',
        builder: (context, state) => const SocialLinksScreen(),
      ),
      GoRoute(
        path: '/store/preview',
        builder: (context, state) {
          final store = state.extra as StoreModel;
          return StorePreviewScreen(store: store);
        },
      ),
      GoRoute(
        path: '/profile/payouts',
        builder: (context, state) => const PayoutsScreen(),
      ),
      GoRoute(
        path: '/profile/support',
        builder: (context, state) => const VendorHelpSupportScreen(),
      ),
      GoRoute(
        path: '/profile/accounts',
        builder: (context, state) => const VendorAccountsScreen(),
      ),
      GoRoute(
        path: '/analytics/revenue',
        builder: (context, state) => const RevenueAnalyticsScreen(),
      ),
      GoRoute(
        path: '/analytics/orders',
        builder: (context, state) => const OrdersAnalyticsScreen(),
      ),
      GoRoute(
        path: '/analytics/products',
        builder: (context, state) => const ProductsAnalyticsScreen(),
      ),
      GoRoute(
        path: '/analytics/followers',
        builder: (context, state) => const FollowersAnalyticsScreen(),
      ),
      GoRoute(
        path: '/analytics/rating',
        builder: (context, state) => const RatingsAnalyticsScreen(),
      ),

      GoRoute(
        path: '/analytics/earnings',
        builder: (context, state) => const EarningsPayoutsScreen(),
      ),
      GoRoute(
        path: '/profile/feedback',
        builder: (context, state) => const CustomerFeedbackScreen(),
      ),
      GoRoute(
        path: '/profile/payouts',
        builder: (context, state) => const PayoutsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionDashboardScreen(),
      ),
    ],
    redirect: (context, state) {
      // We will handle most redirections inside SplashScreen or AuthListener
      // to avoid complex GoRouter redirect loops.
      return null;
    },
  );
}
