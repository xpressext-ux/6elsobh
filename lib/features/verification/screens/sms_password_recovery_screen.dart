import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class SmsPasswordRecoveryScreen extends StatefulWidget {
  final String? initialPhone;

  const SmsPasswordRecoveryScreen({super.key, this.initialPhone});
  @override
  State<SmsPasswordRecoveryScreen> createState() =>
      _SmsPasswordRecoveryScreenState();
}

class _SmsPasswordRecoveryScreenState extends State<SmsPasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? _challengeToken;
  List<String> _names = const [];
  bool _loading = false;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.initialPhone ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadNames() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final response = await Get.find<ApiClient>().postData(
      AppConstants.passwordRecoveryOptionsUri,
      {'phone': _phoneController.text.trim()},
      handleError: false,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (response.statusCode == 200 && response.body is Map) {
      // ApiClient unwraps the current API envelope on successful responses.
      final content = response.body['content'] is Map
          ? response.body['content'] as Map
          : response.body as Map;
      setState(() {
        _challengeToken = content['challenge_token']?.toString();
        _names = (content['names'] as List? ?? [])
            .map((e) => e.toString())
            .toList();
      });
    } else {
      _showMessage(
        response.statusText ??
            response.body['message']?.toString() ??
            'password_recovery_account_not_found'.tr,
      );
    }
  }

  Future<void> _verifyName(int index) async {
    if (_challengeToken == null || _locked) return;
    setState(() => _loading = true);
    final response = await Get.find<ApiClient>()
        .postData(AppConstants.passwordRecoveryVerifyUri, {
          'phone': _phoneController.text.trim(),
          'challenge_token': _challengeToken,
          'selected_index': index,
        }, handleError: false);
    if (!mounted) return;
    setState(() => _loading = false);
    if (response.statusCode == 200 &&
        ((response.body['content'] is Map &&
                response.body['content']['sent'] == true) ||
            (response.body is Map && response.body['sent'] == true))) {
      _showSuccessDialog();
    } else {
      setState(() {
        _locked = true;
        _names = const [];
      });
      final dynamic body = response.body;
      final dynamic errors = body is Map ? body['errors'] : null;
      final dynamic firstError = errors is List && errors.isNotEmpty
          ? errors.first
          : null;
      final String errorCode = firstError is Map
          ? firstError['code']?.toString() ?? ''
          : '';
      _showMessage(
        errorCode == 'not-found'
            ? 'password_recovery_invalid_name'.tr
            : firstError is Map && firstError['message'] != null
            ? firstError['message'].toString()
            : body is Map && body['message'] != null
            ? body['message'].toString()
            : 'password_recovery_no_attempts'.tr,
      );
    }
  }

  void _showMessage(String message) => Get.snackbar(
    'sms_password_recovery_title'.tr,
    message,
    snackPosition: SnackPosition.BOTTOM,
  );

  void _showSuccessDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          Dimensions.paddingSizeLarge,
          Dimensions.paddingSizeLarge,
          Dimensions.paddingSizeLarge,
          Dimensions.paddingSizeSmall,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Theme.of(Get.context!).primaryColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sms_rounded,
                size: 43,
                color: Theme.of(Get.context!).primaryColor,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text(
              'password_sent_successfully'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'password_sent_success_message'.tr,
              style: robotoRegular.copyWith(
                color: Theme.of(Get.context!).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                Get.back();
              },
              child: Text('got_it'.tr),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final choosingName =
        _challengeToken != null && _names.isNotEmpty && !_locked;
    return Scaffold(
      appBar: CustomAppBar(title: 'sms_password_recovery_title'.tr),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeLarge,
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeLarge,
              Dimensions.paddingSizeLarge,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: Dimensions.paddingSizeSmall,
                    ),
                    child: Image.asset(
                      Images.passwordRecoverySms,
                      width: 148,
                      height: 148,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        Dimensions.paddingSizeLarge,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Text(
                              choosingName
                                  ? 'choose_correct_name_to_send_password'.tr
                                  : 'enter_registered_mobile_number'.tr,
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeLarge,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: Dimensions.paddingSizeLarge),
                            if (!choosingName && !_locked) ...[
                              CustomTextField(
                                controller: _phoneController,
                                inputType: TextInputType.phone,
                                labelText: 'mobile_number'.tr,
                                titleText: 'mobile_number_example'.tr,
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                    ? 'enter_mobile_number'.tr
                                    : null,
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeLarge,
                              ),
                              CustomButton(
                                buttonText: 'continue'.tr,
                                isLoading: _loading,
                                onPressed: _loadNames,
                              ),
                            ] else if (choosingName) ...[
                              ...List.generate(
                                _names.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: Dimensions.paddingSizeSmall,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: _loading
                                          ? null
                                          : () => _verifyName(index),
                                      child: Text(_names[index]),
                                    ),
                                  ),
                                ),
                              ),
                              if (_loading)
                                const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(),
                                ),
                            ] else ...[
                              Text(
                                'password_recovery_no_more_attempts'.tr,
                                textAlign: TextAlign.center,
                                style: robotoRegular,
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeLarge,
                              ),
                              CustomButton(
                                buttonText: 'retry'.tr,
                                onPressed: () => setState(() {
                                  _locked = false;
                                  _challengeToken = null;
                                  _names = const [];
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
