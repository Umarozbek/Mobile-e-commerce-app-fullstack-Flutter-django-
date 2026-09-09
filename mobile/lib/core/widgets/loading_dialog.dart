
import 'package:flutter/material.dart';

import '../constans/app_colors.dart';
import '../constans/app_sizes.dart';

void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Foydalanuvchi ekranga urib yopib qo'ymasligi uchun
    builder: (context) {
      return Center(
        child: Container(
          width: AppDimens.s100,
          height: AppDimens.s100,
          decoration: BoxDecoration(
            color: Colors.white, // Orqa fon rangi
            borderRadius: BorderRadius.circular(AppDimens.s20), // Burchaklarni yumshatish
          ),
          padding: EdgeInsets.all(AppDimens.s20),
          child: const CircularProgressIndicator(
            strokeWidth: AppDimens.s5, // Chiziq qalinligi
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary), // Rangini loyihaga moslang
          ),
        ),
      );
    },
  );
}