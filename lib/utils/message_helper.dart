import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Helper class to get localized error and success messages
class MessageHelper {
  /// Get localized message from message key
  static String getMessage(BuildContext context, String messageKey) {
    final l10n = AppLocalizations.of(context)!;

    switch (messageKey) {
      // Error messages
      case 'errorNoInternet':
        return l10n.errorNoInternet;
      case 'errorTimeout':
        return l10n.errorTimeout;
      case 'errorConnection':
        return l10n.errorConnection;
      case 'errorNetwork':
        return l10n.errorNetwork;
      case 'errorServerError':
        return l10n.errorServerError;
      case 'errorNotFound':
        return l10n.errorNotFound;
      case 'errorUnauthorized':
        return l10n.errorUnauthorized;
      case 'errorForbidden':
        return l10n.errorForbidden;
      case 'errorBadRequest':
        return l10n.errorBadRequest;
      case 'errorConflict':
        return l10n.errorConflict;
      case 'errorBadGateway':
        return l10n.errorBadGateway;
      case 'errorServiceUnavailable':
        return l10n.errorServiceUnavailable;
      case 'errorGatewayTimeout':
        return l10n.errorGatewayTimeout;
      case 'errorClientError':
        return l10n.errorClientError;
      case 'errorInvalidResponse':
        return l10n.errorInvalidResponse;
      case 'errorGeneric':
        return l10n.errorGeneric;
      case 'errorNotAuthenticated':
        return l10n.errorNotAuthenticated;
      case 'errorInvalidCredentials':
        return l10n.errorInvalidCredentials;
      case 'errorUserExists':
        return l10n.errorUserExists;
      case 'errorProductNotFound':
        return l10n.errorProductNotFound;
      case 'errorInsufficientStock':
        return l10n.errorInsufficientStock;

      // Success messages
      case 'successLogin':
        return l10n.successLogin;
      case 'successSignup':
        return l10n.successSignup;
      case 'successLogout':
        return l10n.successLogout;
      case 'successReservationCreated':
        return l10n.successReservationCreated;
      case 'successReservationCancelled':
        return l10n.successReservationCancelled;
      case 'successReservationFulfilled':
        return l10n.successReservationFulfilled;
      case 'successQuantityUpdated':
        return l10n.successQuantityUpdated;
      case 'successGeneric':
        return l10n.successGeneric;

      // Helper messages
      case 'tryAgainLater':
        return l10n.tryAgainLater;
      case 'checkConnection':
        return l10n.checkConnection;
      case 'contactSupport':
        return l10n.contactSupport;

      default:
        return l10n.errorGeneric;
    }
  }

  /// Show a SnackBar with localized message
  static void showMessage(
    BuildContext context,
    String messageKey, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final message = getMessage(context, messageKey);
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: l10n.close,
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show error message from API response
  static void showApiResponse(
    BuildContext context,
    Map<String, dynamic> response,
  ) {
    final messageKey = response['messageKey'] ?? 'errorGeneric';
    final isSuccess = response['success'] ?? false;

    showMessage(context, messageKey, isError: !isSuccess);
  }

  /// Show error dialog with localized message
  static Future<void> showErrorDialog(
    BuildContext context,
    String messageKey, {
    String? title,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final message = getMessage(context, messageKey);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? l10n.error),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
  }

  /// Show success dialog with localized message
  static Future<void> showSuccessDialog(
    BuildContext context,
    String messageKey, {
    String? title,
    VoidCallback? onOk,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final message = getMessage(context, messageKey);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? l10n.success),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOk?.call();
              },
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
  }
}

/// Extension to easily show messages from API responses
extension ApiResponseExtension on Map<String, dynamic> {
  void showMessage(BuildContext context) {
    MessageHelper.showApiResponse(context, this);
  }

  String getLocalizedMessage(BuildContext context) {
    final messageKey = this['messageKey'] ?? 'errorGeneric';
    return MessageHelper.getMessage(context, messageKey);
  }
}
