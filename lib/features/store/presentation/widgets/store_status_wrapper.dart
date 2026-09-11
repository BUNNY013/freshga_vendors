import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../screens/suspended_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/providers/auth_provider.dart' as auth;

class StoreStatusWrapper extends StatelessWidget {
  final Widget child;

  const StoreStatusWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer2<StoreProvider, auth.AuthProvider>(
      builder: (context, storeProvider, authProvider, originalChild) {
        final store = storeProvider.store;
        // Rely on AuthProvider's state or FirebaseAuth directly, 
        // but now Consumer2 guarantees a rebuild on logout!
        final isLoggedIn = FirebaseAuth.instance.currentUser != null;

        return Stack(
          children: [
            // Always keep the original child mounted in the tree!
            // This ensures any in-flight routing (like from /otp to /splash) completes successfully
            // behind the scenes.
            child,
            
            // If store is suspended AND user is actually logged in, overlay the SuspendedScreen entirely.
            if (isLoggedIn && store != null && store.status == 'Suspended')
              Positioned.fill(
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  home: SuspendedScreen(reason: store.suspensionReason),
                ),
              ),
          ],
        );
      },
      child: child,
    );
  }
}
