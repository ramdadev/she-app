// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:toastification/toastification.dart';

class ToastificationService {
  void showError(String title, String message) {
    toastification.dismissAll();

    toastification.show(
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: Text(
        title,
        style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
      ),
      description: Text(message, style: const TextStyle(fontSize: 12.0)),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 5),
      closeButton: ToastCloseButton(showType: CloseButtonShowType.none),
      showProgressBar: false,
    );
  }

  void showInfo(String title, String message) {
    toastification.dismissAll();

    toastification.show(
      type: ToastificationType.info,
      style: ToastificationStyle.fillColored,
      title: Text(
        title,
        style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
      ),
      description: Text(message, style: const TextStyle(fontSize: 12.0)),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 5),
      closeButton: ToastCloseButton(showType: CloseButtonShowType.none),
      showProgressBar: false,
    );
  }

  void showSuccess(String title, String message) {
    toastification.dismissAll();

    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: Text(
        title,
        style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
      ),
      description: Text(message, style: const TextStyle(fontSize: 12.0)),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 5),
      closeButton: ToastCloseButton(showType: CloseButtonShowType.none),
      showProgressBar: false,
    );
  }

  void showWarning(String title, String message) {
    toastification.dismissAll();

    toastification.show(
      type: ToastificationType.warning,
      style: ToastificationStyle.fillColored,
      title: Text(
        title,
        style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
      ),
      description: Text(message, style: const TextStyle(fontSize: 12.0)),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 5),
      closeButton: ToastCloseButton(showType: CloseButtonShowType.none),
      showProgressBar: false,
    );
  }
}
