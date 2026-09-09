import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mart/features/auth/presentation/page/set_password_page.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/constans/app_text_styles.dart';
import '../../../../core/extention/padding_extention.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/cupertino_alert_dialog.dart';
import '../../../../core/widgets/loading_dialog.dart';
import '../../../../core/widgets/universal_button.dart';
import '../cubit/auth_cubit.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;
  final String fullName;
  final String? referralCode;
  /// Backend register response da `otp_debug` yuborsa (faqat dev/test) — avtoto'ldiriladi.
  /// Production da backend bu maydonni yubormaydi, foydalanuvchi SMS dagi kodni o'zi kiritadi.
  final String? otpDebug;
  /// Register javobidagi referral_bonus_given flag.
  final bool referralBonusGiven;

  const OtpPage({
    super.key,
    required this.phoneNumber,
    required this.fullName,
    this.referralCode,
    this.otpDebug,
    this.referralBonusGiven = false,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController otpController = TextEditingController();
  Timer? _timer;
  int remainingSeconds = 180; // 3 daqiqa = 180 soniya
  bool _canResend = false;
  /// OTP tekshiruv so'rovi faqat bir marta yuborilishi uchun qo'riq.
  bool _verifyOtpSent = false;

  void _sendVerifyOtp(String otp) {
    if (_verifyOtpSent) return;
    _verifyOtpSent = true;
    context.read<AuthCubit>().verifyOtp(
      otp: otp,
      phone: widget.phoneNumber,
    );
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Backend otp_debug yuborgan bo'lsa (dev) — avtoto'ldirish; production da null keladi.
    if (widget.otpDebug != null && widget.otpDebug!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final otp = widget.otpDebug!.length > 4
            ? widget.otpDebug!.substring(0, 4)
            : widget.otpDebug!;
        otpController.text = otp;
        if (otp.length == 4) {
          _sendVerifyOtp(otp);
        }
      });
    }
  }

  void _startTimer() {
    _canResend = false;
    remainingSeconds = 180;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _resendOtp() {
    if (_canResend) {
      _verifyOtpSent = false;
      otpController.clear();
      context.read<AuthCubit>().resendOtp(
        number: widget.phoneNumber,
        fullName: widget.fullName,
        referralCode: widget.referralCode,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(
        fontSize: 24,
        color: Theme.of(context).textTheme.headlineSmall?.color,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(AppDimens.r12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primary),
      borderRadius: BorderRadius.circular(AppDimens.r12),
    );

    final submittedPinTheme = defaultPinTheme.copyDecorationWith(
      color: AppColors.primary.withOpacity(0.1),
      border: Border.all(color: AppColors.primary),
      borderRadius: BorderRadius.circular(AppDimens.r12),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          showNiceAlertDialog(
            context,
            title: 'exit_confirm_title'.tr(),
            content: 'exit_confirm_msg'.tr(),
            onPressed: () {
              Navigator.pop(context);
            },
          );
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: null,
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess && state.type == AuthType.verifyOtp) {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SetPasswordPage(
                    phoneNumber: widget.phoneNumber,
                    referralBonusGiven: widget.referralBonusGiven,
                  ),
                ),
              );
            }

            if (state is AuthLoading && state.type == AuthType.verifyOtp) {
              showLoadingDialog(context);
            } else if (state is AuthError && state.type == AuthType.verifyOtp) {
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

            if (state is AuthLoading && state.type == AuthType.resendOtp) {
              showLoadingDialog(context);
            } else if (state is AuthSuccess && state.type == AuthType.resendOtp) {
              Navigator.pop(context);
              _startTimer();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('otp_sent'.tr()),
                  duration: Duration(seconds: 2),
                ),
              );
            } else if (state is AuthError && state.type == AuthType.resendOtp) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimens.s40),
                  Text(
                    'otp_title'.tr(),
                    style: AppTextStyles.h1.copyWith(
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                    ),
                  ).paddingSymmetric(horizontal: AppDimens.s20),
                  const SizedBox(height: AppDimens.s8),
                  Text(
                    'otp_subtitle'.tr(namedArgs: {'phone': widget.phoneNumber}),
                    textAlign: TextAlign.left,
                    style: AppTextStyles.bodyM.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ).paddingSymmetric(horizontal: AppDimens.s20),
                  const SizedBox(height: AppDimens.s32),
                  Center(
                    child: Pinput(
                      length: 4,
                      controller: otpController,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      showCursor: true,
                      onCompleted: (pin) {
                        _sendVerifyOtp(pin);
                      },
                    ).paddingSymmetric(horizontal: AppDimens.s20),
                  ),
                  const SizedBox(height: AppDimens.s40),
                  Center(
                    child: Column(
                      children: [
                        // if (!_canResend)
                        //   Text(
                        //     'otp_timer'.tr(namedArgs: {'time': _formatTime(remainingSeconds)}),
                        //     style: AppTextStyles.bodyM.copyWith(
                        //       color: AppColors.secondaryText,
                        //     ),
                        //   ),
                        // if (_canResend)
                        UniversalButton.filled(
                          margin: EdgeInsets.symmetric(horizontal: AppDimens.s16),
                          text: !_canResend
                              ? 'otp_timer'.tr(namedArgs: {
                                  'time': _formatTime(remainingSeconds)
                                })
                              : 'otp_resend'.tr(),
                          onPressed: _canResend ? _resendOtp : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.s24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
