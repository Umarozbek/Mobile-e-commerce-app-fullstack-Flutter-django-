import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mart/features/auth/presentation/page/sign_up.dart';

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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isPasswordVisible = false;
  bool _isLoadingDialogOpen = false;
  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  void _dismissLoadingDialog() {
    if (_isLoadingDialogOpen) {
      _isLoadingDialogOpen = false;
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: null,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess && state.type == AuthType.login) {
            _dismissLoadingDialog();
            // Login muvaffaqiyatli bo'lsa, eski (GetStorage dagi) tokenni o'chiramiz
            final box = GetStorage();
            box.remove('access_token');
            // FCM token endi mavjud JWT bilan backendga ro'yxatdan o'tkaziladi.
            // Xatolik bo'lsa ham login oqimini to'xtatmaydi (ichida try/catch bor).
            sl<FirebaseMessagingService>().registerDeviceToken();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainPage()),
              (route) => false,
            );
          }

          if (state is AuthLoading && state.type == AuthType.login) {
            _isLoadingDialogOpen = true;
            showLoadingDialog(context);
          }

          if (state is AuthError && state.type == AuthType.login) {
            _dismissLoadingDialog();
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
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppDimens.s5,
                children: [
                  Spacer(),
                  // Welcome title
                  Text(
                    'login_welcome_title'.tr(),
                    style: AppTextStyles.h1.copyWith(
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                    ),
                  ),

                  Text(
                    'login_welcome_subtitle'.tr(),
                    style: AppTextStyles.bodyM.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: AppDimens.s20),
                  // Phone field
                  AppTextField(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(
                        left: AppDimens.s20,
                        top: AppDimens.s14,
                        bottom: AppDimens.s12,
                      ),
                      child: Text(
                        "+82 ",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w500,
                          fontSize: AppDimens.s16,
                        ),
                      ),
                    ),
                    isOnTapOutside: true,
                    formatter: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    keyboardType: TextInputType.phone,
                    controller: phoneController,
                    title: 'phone_label'.tr(),
                    hintText: 'phone_hint'.tr(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'phone_required'.tr();
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppDimens.s5),
                  // Password field
                  AppTextField(
                    controller: passwordController,
                    isOnTapOutside: true,
                    title: 'password_label'.tr(),
                    hintText: 'password_hint'.tr(),
                    obscureText: !isPasswordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'password_required'.tr();
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  // Forgot password aligned to the right
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SignUp(number: phoneController.text),
                          ),
                        );
                      },
                      child: Text(
                        'forgot_password_btn'.tr(),
                        style: AppTextStyles.bodyM.copyWith(
                          color:isDarkMode ? Colors.white : AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.s16),
                  // Primary button
                  UniversalButton.filled(
                    text: 'sign_in'.tr(),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        context.read<AuthCubit>().login(
                              number: "+82${phoneController.text.replaceAll(" ", "")}",
                              password: passwordController.text,
                            );
                      }
                    },
                  ),
                  const SizedBox(height: AppDimens.s20),
                  // Divider with "no account" text
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.s8),
                        child: Text(
                          'login_no_account'.tr(),
                          style: AppTextStyles.bodyS.copyWith(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.s10),
                  // Sign up link
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SignUp(number: phoneController.text),
                          ),
                        );
                      },
                      child: Text(
                        'sign_up_btn'.tr(),
                        style: AppTextStyles.bodyMBold.copyWith(
                          color:isDarkMode ?AppColors.primaryDark : AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  Spacer()
                ],
              ).paddingSymmetric(horizontal: AppDimens.s20),
            ),
          );
        },
      ),
    );
  }
}
