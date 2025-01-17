import 'dart:convert';
import 'dart:io';

import 'package:at_onboarding_flutter/screen/at_onboarding_accounts_screen.dart';
import 'package:at_onboarding_flutter/screen/at_onboarding_reference_screen.dart';
import 'package:at_onboarding_flutter/services/free_atsign_service.dart';
import 'package:at_onboarding_flutter/utils/at_onboarding_dimens.dart';
import 'package:at_onboarding_flutter/utils/at_onboarding_input_formatter.dart';
import 'package:at_onboarding_flutter/utils/at_onboarding_strings.dart';
import 'package:at_onboarding_flutter/widgets/at_onboarding_button.dart';
import 'package:at_onboarding_flutter/widgets/at_onboarding_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:url_launcher/url_launcher.dart';

class AtOnboardingOTPResult {
  String atSign;
  String? secret;

  AtOnboardingOTPResult({
    required this.atSign,
    required this.secret,
  });
}

class AtOnboardingOTPScreen extends StatefulWidget {
  static Future<AtOnboardingOTPResult?> push({
    required BuildContext context,
    required String atSign,
    String? email,
    required bool hideReferences,
  }) {
    return Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AtOnboardingOTPScreen(
                  atSign: atSign,
                  email: email,
                  hideReferences: hideReferences,
                )));
  }

  final String atSign;
  final String? email;

  ///will hide webpage references.
  final bool hideReferences;

  const AtOnboardingOTPScreen({
    Key? key,
    required this.atSign,
    this.email,
    required this.hideReferences,
  }) : super(key: key);

  @override
  State<AtOnboardingOTPScreen> createState() => _AtOnboardingOTPScreenState();
}

class _AtOnboardingOTPScreenState extends State<AtOnboardingOTPScreen> {
  final TextEditingController _pinCodeController = TextEditingController();
  final FreeAtsignService _freeAtsignService = FreeAtsignService();

  bool isVerifing = false;
  bool isResendingCode = false;

  String limitExceeded = 'limitExceeded';

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isVerifing,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Setting up your account',
            style: TextStyle(
              color: Platform.isIOS || Platform.isAndroid
                  ? Theme.of(context).brightness == Brightness.light
                      ? Colors.black
                      : Colors.white
                  : null,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _showReferenceWebview,
              icon: const Icon(Icons.help),
            ),
          ],
        ),
        body: Center(
          child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(AtOnboardingDimens.borderRadius)),
            padding: const EdgeInsets.all(AtOnboardingDimens.paddingNormal),
            margin: const EdgeInsets.all(AtOnboardingDimens.paddingNormal),
            constraints: const BoxConstraints(
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enter Verification Code',
                  style: TextStyle(
                    fontSize: AtOnboardingDimens.fontLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                PinCodeTextField(
                  controller: _pinCodeController,
                  animationType: AnimationType.none,
                  textCapitalization: TextCapitalization.characters,
                  appContext: context,
                  length: 4,
                  textStyle: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  pinTheme: PinTheme(
                    selectedColor: Theme.of(context).primaryColor,
                    inactiveColor: Colors.grey[500],
                    activeColor: Theme.of(context).primaryColor,
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(5),
                    fieldHeight: 48,
                    fieldWidth: MediaQuery.of(context).size.width > 400
                        ? 80
                        : (MediaQuery.of(context).size.width - 100) / 4,
                  ),
                  cursorHeight: 24,
                  cursorColor: Colors.grey,
                  // controller: _otpController,
                  keyboardType: TextInputType.text,
                  inputFormatters: <TextInputFormatter>[
                    AtOnboardingInputFormatter(),
                  ],
                  onChanged: (String value) {},
                ),
                Text(
                  'A verification code has been sent to ${widget.email ?? 'your registered email.'}',
                  style:
                      const TextStyle(fontSize: AtOnboardingDimens.fontNormal),
                ),
                const SizedBox(height: 10),
                AtOnboardingPrimaryButton(
                  height: 48,
                  borderRadius: 24,
                  width: double.infinity,
                  isLoading: isVerifing,
                  onPressed: _onVerifyPressed,
                  child: Text(
                    'Verify & Login',
                    style: TextStyle(
                      color: Platform.isIOS || Platform.isAndroid
                          ? Theme.of(context).brightness == Brightness.light
                              ? Colors.white
                              : Colors.black
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AtOnboardingSecondaryButton(
                  height: 48,
                  borderRadius: 24,
                  width: double.infinity,
                  isLoading: isResendingCode,
                  onPressed: _onResendPressed,
                  child: const Text('Resend Code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showErrorDialog(String? errorMessage) async {
    return AtOnboardingDialog.showError(
        context: context, message: errorMessage ?? '');
  }

  void _showReferenceWebview() {
    if (Platform.isAndroid || Platform.isIOS) {
      AtOnboardingReferenceScreen.push(
        context: context,
        title: AtOnboardingStrings.faqTitle,
        url: AtOnboardingStrings.faqUrl,
      );
    } else {
      launchUrl(
        Uri.parse(
          AtOnboardingStrings.faqUrl,
        ),
      );
    }
  }

  void _onVerifyPressed() async {
    if ((widget.email ?? '').isEmpty) {
      isVerifing = true;
      setState(() {});
      final secret = await validatewithAtsign(
          widget.atSign, _pinCodeController.text, context);
      isVerifing = false;
      setState(() {});
      if (!mounted) return;
      Navigator.pop(context,
          AtOnboardingOTPResult(atSign: widget.atSign, secret: secret));
      return;
    }
    isVerifing = true;
    setState(() {});

    String? result = await validatePerson(
        widget.atSign, widget.email!, _pinCodeController.text);

    isVerifing = false;
    setState(() {});
    if (result != null && result != limitExceeded) {
      List<String> params = result.split(':');
      if (!mounted) return;
      Navigator.pop(
          context, AtOnboardingOTPResult(atSign: params[0], secret: params[1]));
    }
  }

  ///With activate account
  Future<String> validatewithAtsign(
      String atsign, String otp, BuildContext context,
      {bool isConfirmation = false}) async {
    dynamic data;
    String? cramSecret;

    dynamic response =
        await _freeAtsignService.verificationWithAtsign(atsign, otp);
    if (response.statusCode == 200) {
      data = response.body;
      data = jsonDecode(data);
      //check for the atsign list and display them.
      if (data['message'] == 'Verified') {
        cramSecret = data['cramkey'];
      } else {
        String errorMessage = data['message'];
        await showErrorDialog(errorMessage);
      }
    } else {
      data = response.body;
      data = jsonDecode(data);
      String errorMessage = data['message'];
      await showErrorDialog(errorMessage);
    }
    return cramSecret ?? '';
  }

  Future<bool> loginWithAtsign(String atsign, BuildContext context) async {
    dynamic data;
    bool status = false;

    dynamic response = await _freeAtsignService.loginWithAtsign(atsign);
    if (response.statusCode == 200) {
      data = response.body;
      data = jsonDecode(data);

      status = true;
      // atsign = data['data']['atsign'];
    } else {
      data = response.body;
      data = jsonDecode(data);
      String errorMessage = data['message'];
      await showErrorDialog(errorMessage);
    }
    return status;
  }

  ///With new account
  void _onResendPressed() async {
    if ((widget.email ?? '').isEmpty) {
      loginWithAtsign(widget.atSign, context);
      return;
    }

    setState(() {
      isResendingCode = true;
    });
    // String atsign;
    dynamic response =
        await _freeAtsignService.registerPerson(widget.atSign, widget.email!);
    if (response.statusCode == 200) {
      //Success
      _pinCodeController.text = '';
      // status = true;
      // atsign = data['data']['atsign'];
    } else {
      //Error
      final data = jsonDecode(response.body);
      String errorMessage = data['message'];
      // if (errorMessage.contains('Invalid Email')) {
      //   oldEmail = email;
      // }
      if (errorMessage.contains('maximum number of free atSigns')) {
        await showlimitDialog();
      } else {
        await showErrorDialog(errorMessage);
      }
    }
    setState(() {
      isResendingCode = false;
    });
  }

  Future<String?> validatePerson(String atsign, String email, String? otp,
      {bool isConfirmation = false}) async {
    dynamic data;
    String? cramSecret;
    List<String> atsigns = <String>[];
    // String atsign;

    dynamic response = await _freeAtsignService
        .validatePerson(atsign, email, otp, confirmation: isConfirmation);
    if (response.statusCode == 200) {
      data = response.body;
      data = jsonDecode(data);
      //check for the atsign list and display them.
      if (data['data'] != null &&
          data['data'].length == 2 &&
          data['status'] != 'error') {
        dynamic responseData = data['data'];
        atsigns.addAll(List<String>.from(responseData['atsigns']));

        if (responseData['newAtsign'] == null) {
          if (!mounted) return null;
          final value = await Navigator.push(
              context,
              MaterialPageRoute<String?>(
                  builder: (_) => AtOnboardingAccountsScreen(
                        atsigns: atsigns,
                        message: responseData['message'],
                      )));
          if (value != null) {
            if (!mounted) return null;
            Navigator.pop(
                context, AtOnboardingOTPResult(atSign: value, secret: null));
          }
          return null;
        }
        //displays list of atsign along with newAtsign
        else {
          if (!mounted) return null;
          final value = await Navigator.push(
              context,
              MaterialPageRoute<String?>(
                  builder: (_) => AtOnboardingAccountsScreen(
                        atsigns: atsigns,
                        newAtsign: responseData['newAtsign']!,
                      )));
          if (value == responseData['newAtsign']) {
            cramSecret = await validatePerson(value as String, email, otp,
                isConfirmation: true);
            return cramSecret;
          } else {
            if (value != null) {
              if (!mounted) return null;
              Navigator.pop(
                  context, AtOnboardingOTPResult(atSign: value, secret: null));
            }
            return null;
          }
        }
      } else if (data['status'] != 'error') {
        cramSecret = data['cramkey'];
      } else {
        String? errorMessage = data['message'];
        await showErrorDialog(errorMessage);
      }
      // atsign = data['data']['atsign'];
    } else {
      data = response.body;
      data = jsonDecode(data);
      String? errorMessage = data['message'];
      await showErrorDialog(errorMessage);
    }
    return cramSecret;
  }

  Future<bool> registerPersona(
      String atsign, String email, BuildContext context,
      {String? oldEmail}) async {
    dynamic data;
    bool status = false;
    // String atsign;
    dynamic response = await _freeAtsignService.registerPerson(atsign, email,
        oldEmail: oldEmail);
    if (response.statusCode == 200) {
      data = response.body;
      data = jsonDecode(data);
      status = true;
    } else {
      data = response.body;
      data = jsonDecode(data);
      String errorMessage = data['message'];
      if (errorMessage.contains('Invalid Email')) {
        oldEmail = email;
      }
      if (errorMessage.contains('maximum number of free atSigns')) {
        await showlimitDialog();
      } else {
        await showErrorDialog(errorMessage);
      }
    }
    return status;
  }

  Future<AlertDialog?> showlimitDialog() async {
    return showDialog<AlertDialog>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: RichText(
              text: TextSpan(
                children: <InlineSpan>[
                  const TextSpan(
                    style: TextStyle(
                        color: Colors.black, fontSize: 16, letterSpacing: 0.5),
                    text:
                        'Oops! You already have the maximum number of free atSigns. Please login to ',
                  ),
                  TextSpan(
                      text: 'https://my.atsign.com',
                      style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                          letterSpacing: 0.5,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          String url = 'https://my.atsign.com';
                          if (!widget.hideReferences &&
                              await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                        }),
                  const TextSpan(
                    text: '  to select one of your existing atSigns.',
                    style: TextStyle(
                        color: Colors.black, fontSize: 16, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Close',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ))
            ],
          );
        });
  }
}
