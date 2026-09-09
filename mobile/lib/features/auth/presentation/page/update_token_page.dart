import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../dependencies_injection.dart';
import '../../domain/repository/auth_repository.dart';
import 'login_page.dart';
import '../../../main/presentation/page/main_page.dart';

/// GetStorage da eski token bo'lsa shu sahifaga yo'naltiriladi.
/// Eski tokenni API ga yuborib yangi JWT oladi va davom etadi (login qilgandek).
class UpdateTokenPage extends StatefulWidget {
  const UpdateTokenPage({super.key});

  @override
  State<UpdateTokenPage> createState() => _UpdateTokenPageState();
}

class _UpdateTokenPageState extends State<UpdateTokenPage> {
  String? _oldToken;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryUpdateToken());
  }

  Future<void> _tryUpdateToken() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final box = GetStorage();
    final oldToken = box.read('access_token');
    final tokenStr = oldToken?.toString().trim() ?? '';

    if (tokenStr.isEmpty) {
      _goToLogin();
      return;
    }

    setState(() {
      _oldToken = tokenStr;
    });

    final authRepo = sl<AuthRepository>();
    final result = await authRepo.updateToken(tokenStr);

    if (!mounted) return;

    result.fold(
      (failure) {
        // 404 (token topilmadi) bo'lsa loginga yo'naltiramiz, eski tokenni o'chirmaymiz
        if (failure.statusCode == 404) {
          _goToLogin();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.error;
          });
        }
      },
      (_) async {
        // Muvaffaqiyatli yangilangandan so'ng eski tokenni GetStorage dan o'chiramiz
        await box.remove('access_token');
        _goToMain();
      },
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _goToMain() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String errorText = _errorMessage != null
        ? ErrorUtils.getErrorMessage(_errorMessage!, context)
        : 'error'.tr();

    return Scaffold(
      backgroundColor: AppColors.bgMainDark,
      body: Center(
        child: _isLoading
            ? const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      errorText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _tryUpdateToken,
                      child: Text('retry'.tr()),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
