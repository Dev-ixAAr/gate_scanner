import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../models/setup_qr_payload.dart';
import '../providers/setup_provider.dart';
import '../widgets/setup_confirmation_sheet.dart';

/// Manual setup screen — enter server_url, event_public_ref, setup_token.
class SetupManualScreen extends ConsumerStatefulWidget {
  const SetupManualScreen({super.key});

  @override
  ConsumerState<SetupManualScreen> createState() => _SetupManualScreenState();
}

class _SetupManualScreenState extends ConsumerState<SetupManualScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _eventRefController = TextEditingController();
  final _setupTokenController = TextEditingController();

  bool _isBottomSheetVisible = false;
  String? _parseError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(setupExchangeProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _eventRefController.dispose();
    _setupTokenController.dispose();
    super.dispose();
  }

  void _handleExchangeStateChange(
    SetupExchangeState? previous,
    SetupExchangeState next,
  ) {
    if (next is SetupExchangeSuccessState) {
      if (_isBottomSheetVisible) {
        Navigator.of(context).pop();
        _isBottomSheetVisible = false;
      }
      context.go(RouteNames.home);
    } else if (next is SetupExchangeErrorState) {
      if (_isBottomSheetVisible) {
        Navigator.of(context, rootNavigator: true).popUntil(
          (route) => route.isFirst,
        );
        _isBottomSheetVisible = false;
      }
      _showExchangeErrorSnackbar(next);
    }
  }

  void _showExchangeErrorSnackbar(SetupExchangeErrorState errorState) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    errorState.isNetworkError
                        ? Icons.wifi_off_rounded
                        : Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Connection Failed',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Text(
                  errorState.message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.backgroundTertiary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.errorBorder),
          ),
        ),
      );
  }

  SetupQrPayload? _buildPayload() {
    try {
      return SetupQrPayload.fromManualEntry(
        serverUrl: _serverUrlController.text,
        eventPublicRef: _eventRefController.text,
        setupToken: _setupTokenController.text,
      );
    } on SetupQrParseException catch (e) {
      setState(() => _parseError = e.message);
      return null;
    }
  }

  void _onContinue() {
    setState(() => _parseError = null);
    if (!_formKey.currentState!.validate()) return;

    final payload = _buildPayload();
    if (payload == null) return;

    _showConfirmationSheet(payload);
  }

  void _showConfirmationSheet(SetupQrPayload payload) {
    _isBottomSheetVisible = true;

    showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final exchangeState = ref.watch(setupExchangeProvider);
            final bool isExchanging =
                exchangeState is SetupExchangeLoadingState;

            return SetupConfirmationSheet(
              payload: payload,
              isLoading: isExchanging,
              cancelLabel: 'Edit Details',
              onConfirm: isExchanging
                  ? null
                  : () => ref
                      .read(setupExchangeProvider.notifier)
                      .exchangeSetupToken(payload),
              onCancel: isExchanging
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _isBottomSheetVisible = false;
                      ref.read(setupExchangeProvider.notifier).reset();
                    },
            );
          },
        );
      },
    ).then((_) {
      if (_isBottomSheetVisible) {
        _isBottomSheetVisible = false;
        final exchangeState = ref.read(setupExchangeProvider);
        if (exchangeState is! SetupExchangeSuccessState &&
            exchangeState is! SetupExchangeLoadingState) {
          ref.read(setupExchangeProvider.notifier).reset();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SetupExchangeState>(
      setupExchangeProvider,
      _handleExchangeStateChange,
    );

    final exchangeState = ref.watch(setupExchangeProvider);
    final bool isExchanging = exchangeState is SetupExchangeLoadingState;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: isExchanging
              ? null
              : () {
                  ref.read(setupExchangeProvider.notifier).reset();
                  context.go(RouteNames.setup);
                },
        ),
        title: const Text(
          'Manual Setup',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.screenPaddingHorizontal,
                vertical: AppConstants.screenPaddingVertical,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter the setup details from your admin panel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SetupTextField(
                      controller: _serverUrlController,
                      label: 'Server URL',
                      hint: 'https://events.yourcompany.com',
                      icon: Icons.dns_outlined,
                      keyboardType: TextInputType.url,
                      textCapitalization: TextCapitalization.none,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Server URL is required';
                        }
                        final trimmed = value.trim();
                        if (!trimmed.startsWith('http://') &&
                            !trimmed.startsWith('https://')) {
                          return 'Must start with http:// or https://';
                        }
                        if (kReleaseMode && !trimmed.startsWith('https://')) {
                          return 'HTTPS is required in production builds';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _SetupTextField(
                      controller: _eventRefController,
                      label: 'Event Public Ref',
                      hint: 'EVT-2024-SUMMER-001',
                      icon: Icons.event_outlined,
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Event reference is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _SetupTextField(
                      controller: _setupTokenController,
                      label: 'Setup Token',
                      hint: 'tok_setup_xxxxxxxx',
                      icon: Icons.vpn_key_outlined,
                      obscureText: true,
                      textCapitalization: TextCapitalization.none,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Setup token is required';
                        }
                        return null;
                      },
                    ),
                    if (_parseError != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.errorBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _parseError!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    AppButton.primary(
                      label: 'Continue',
                      leadingIcon: Icons.arrow_forward_rounded,
                      onPressed: isExchanging ? null : _onContinue,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExchanging)
            const Positioned.fill(
              child: LoadingOverlay(message: 'Connecting to event...'),
            ),
        ],
      ),
    );
  }
}

class _SetupTextField extends StatelessWidget {
  const _SetupTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          autocorrect: false,
          validator: validator,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 22),
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.brandPrimary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.errorBorder),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}
