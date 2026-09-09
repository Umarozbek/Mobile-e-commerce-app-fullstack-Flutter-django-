import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/constans/app_text_styles.dart';
import '../../../../core/extention/padding_extention.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_dialog.dart';
import '../../../../core/widgets/universal_button.dart';
import '../cubit/auth_cubit.dart';
import 'otp_page.dart';

class SignUp extends StatefulWidget {
  final String number;

  const SignUp({super.key, required this.number});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  final referralCodeController = TextEditingController();

  @override
  void initState() {
    phoneController.text = widget.number;
    super.initState();
  }

  @override
  void dispose() {
    phoneController.dispose();
    nameController.dispose();
    referralCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: null,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess && state.type == AuthType.signUp) {
            Navigator.pop(context);
            final phoneNumber = "+82${phoneController.text.replaceAll(" ", "")}";

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpPage(
                  phoneNumber: phoneNumber,
                  fullName: nameController.text.trim(),
                  referralCode: referralCodeController.text.trim().isEmpty
                      ? null
                      : referralCodeController.text.trim(),
                  otpDebug: state.otpDebug,
                  referralBonusGiven: state.referralBonusGiven,
                ),
              ),
            );
          }

          if (state is AuthLoading && state.type == AuthType.signUp) {
            showLoadingDialog(context);
          }

          if (state is AuthError && state.type == AuthType.signUp) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ErrorUtils.getErrorMessage(
                    state.failure.error, context)),
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
                spacing: AppDimens.s12,
                children: [
                  const SizedBox(height: AppDimens.s32),
                  Text(
                    'signup_title'.tr(),
                    style: AppTextStyles.h1.copyWith(
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                    ),
                  ),
                  Text(
                    'signup_subtitle'.tr(),
                    style: AppTextStyles.bodyM.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: AppDimens.s5),
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
                const SizedBox(),
                AppTextField(
                  controller: nameController,
                  isOnTapOutside: true,
                  title: 'full_name_label'.tr(),
                  hintText: 'full_name_hint'.tr(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'full_name_required'.tr();
                    }
                    return null;
                  },
                ),
                  const SizedBox(),
                AppTextField(
                  controller: referralCodeController,
                  isOnTapOutside: true,
                  title: 'referral_code'.tr() + ' (${'comment_optional'.tr()})',
                  hintText: 'referral_code_hint'.tr(),
                ),
                Spacer(),
                UniversalButton.filled(
                  text: 'signup_send_code'.tr(),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final referralCode = referralCodeController.text.trim();
                      context.read<AuthCubit>().register(
                            number: "+82${phoneController.text.replaceAll(" ", "")}",
                            fullName: nameController.text.trim(),
                            referralCode: referralCode.isEmpty ? null : referralCode,
                          );
                    }
                  },
                ),
                SizedBox(height: AppDimens.s5,),
                Text(
                  'signup_consent'.tr(),
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                  SizedBox(height: AppDimens.s32),
              ],
              ).paddingSymmetric(horizontal: AppDimens.s20),
            ),
          );
        },
      ),
    );
  }
}
