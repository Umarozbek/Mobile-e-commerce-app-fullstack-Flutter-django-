/// Register API dan qaytadigan ma'lumot (message, referral_code, otp_debug, token).
class RegisterResult {
  final String? token;
  final String? otpDebug;
  final bool referralBonusGiven;

  const RegisterResult({this.token, this.otpDebug, this.referralBonusGiven = false});
}
