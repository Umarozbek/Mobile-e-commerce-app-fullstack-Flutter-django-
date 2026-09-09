import 'package:flutter/material.dart';
import 'package:mart/gen/assets.gen.dart';

import '../../../../core/constans/app_colors.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMainDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image.asset(
            //   Assets.images.logo.path,
            //   width: 120,
            //   height: 120,
            //   errorBuilder: (context, error, stackTrace) => const Icon(
            //     Icons.shopping_bag_outlined,
            //     size: 80,
            //     color: AppColors.primaryDark,
            //   ),
            // ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
