import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constans/app_colors.dart';
import '../constans/app_sizes.dart';



void showNiceAlertDialog(BuildContext context,{required String title,required String content,required VoidCallback onPressed}) {
  showCupertinoDialog(
    context: context,
    builder: (BuildContext ctx) {
      bool isDark=Theme.of(context).brightness==Brightness.dark;
      if(Platform.isIOS){
        return CupertinoAlertDialog(
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              content,
              style: TextStyle(
                fontSize: AppDimens.s15,
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text('cancel'.tr(),style: TextStyle(
                  fontSize: AppDimens.s14,
                  color: AppColors.primary

              ),),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                // Bu yerga amalni yozing
                Navigator.of(ctx).pop();
                onPressed();
              },
              child: Text('yes'.tr(),style: TextStyle(
                  fontSize: AppDimens.s14,
                  color: Colors.red
              )),
            ),
          ],
        );
      }
      return AlertDialog(
        title:  Text(title),
        content:  Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'cancel'.tr(),
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onPressed();
            },
            child: Text(
              'yes'.tr(),
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );

    },
  );
}