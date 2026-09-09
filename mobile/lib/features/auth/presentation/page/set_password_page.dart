
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/constans/app_text_styles.dart';
import '../../../../core/extention/padding_extention.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_dialog.dart';
import '../../../../core/widgets/universal_button.dart';
import '../../../../core/service/firebase_messaging_service.dart';
import '../../../../dependencies_injection.dart';
import '../../../main/presentation/page/main_page.dart';
import '../cubit/auth_cubit.dart';

class SetPasswordPage extends StatefulWidget {

  final String phoneNumber;
  /// Register javobidagi referral_bonus_given flag.
  final bool referralBonusGiven;

  const SetPasswordPage({
    super.key,

    required this.phoneNumber,
    this.referralBonusGiven = false,
  });

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess && state.type == AuthType.setPassword) {
            final password = passwordController.text;
            context.read<AuthCubit>().login(
                  number: widget.phoneNumber,
                  password: password,
                );
          }

          if (state is AuthSuccess && state.type == AuthType.login) {
            Navigator.pop(context);
            // Login muvaffaqiyatli bo'lsa, eski (GetStorage dagi) tokenni o'chiramiz
            final box = GetStorage();
            box.remove('access_token');
            sl<FirebaseMessagingService>().registerDeviceToken();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainPage()),
              (route) => false,
            );
            if (widget.referralBonusGiven) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('referral_friend_bonus_given'.tr()),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }

          if (state is AuthLoading &&
              (state.type == AuthType.setPassword || state.type == AuthType.login)) {
            showLoadingDialog(context);
          }

          if (state is AuthError && state.type == AuthType.setPassword) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    ErrorUtils.getErrorMessage(state.failure.error, context)),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
          }

          if (state is AuthError && state.type == AuthType.login) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    ErrorUtils.getErrorMessage(state.failure.error, context)),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimens.s32),
                    Text(
                      'set_password_title'.tr(),
                      style: AppTextStyles.h1.copyWith(
                        color: Theme.of(context).textTheme.headlineMedium?.color,
                      ),
                    ),
                    const SizedBox(height: AppDimens.s8),
                    Text(
                      'set_password_subtitle'.tr(),
                      textAlign: TextAlign.left,
                      style: AppTextStyles.bodyM.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: AppDimens.s32),
                    AppTextField(
                    controller: passwordController,
                    isOnTapOutside: true,
                    title: 'password_label'.tr(),
                    hintText: 'password_hint'.tr(),
                    obscureText: !isPasswordVisible,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'password_required'.tr();
                      }
                      if (value.length < 6) {
                        return 'password_min_length'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.s16),
                  AppTextField(
                    controller: confirmPasswordController,
                    isOnTapOutside: true,
                    title: 'password_confirm_label'.tr(),
                    hintText: 'password_confirm_hint'.tr(),
                    obscureText: !isConfirmPasswordVisible,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        });
                      },
                      icon: Icon(
                        isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'password_confirm_required'.tr();
                      }
                      if (value != passwordController.text) {
                        return 'password_mismatch'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.s32),
                  UniversalButton.filled(
                    text: 'set_password_btn'.tr(),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        if (passwordController.text == confirmPasswordController.text) {
                          context.read<AuthCubit>().setPassword(
                                password: passwordController.text,
                                phone: widget.phoneNumber,
                              );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('password_mismatch'.tr()),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
                  ).paddingSymmetric(horizontal: AppDimens.s20),
                  const SizedBox(height: AppDimens.s24),
                ],
                ).paddingSymmetric(horizontal: AppDimens.s20),
              ),
            ),
          );
        },
      ),
    );
  }
}
