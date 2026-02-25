import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Utils {
  static String? emailValidator(String? email) {
    final trimmedEmail = email?.trim() ?? '';
    if (trimmedEmail.isEmpty) {
      return 'Please enter your email';
    }
    if (!trimmedEmail.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? passwordValidator(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    List<String> errors = [];

    if (password.length < 8) {
      errors.add('• At least 8 characters long');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('• At least one uppercase letter (A-Z)');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add('• At least one lowercase letter (a-z)');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      errors.add('• At least one digit (0-9)');
    }

    // This covers: ! @ # $ % ^ & * ( ) _ + - = [ ] { } | \ : ; " ' < > , . ? / ~ `
    final specialCharRegex = RegExp(
      r'[!@#$%^&*()_+=\-\[\]{}|\\:;"'
      r"'"
      r'<> ,.?/~`]',
    );
    if (!specialCharRegex.hasMatch(password)) {
      errors.add('• One special character (e.g., @, #, \$, %)');
    }

    if (errors.isEmpty) {
      return null;
    } else {
      return 'Password must include:\n${errors.join('\n')}';
    }
  }

  static String getChildEmail(String parentEmail, String sixDigitCode) {
    final childEmail = parentEmail.replaceFirst(
      '@',
      '+$sixDigitCode@hfs.local',
    );
    return childEmail;
  }

  static void showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      timeInSecForIosWeb: 3,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      timeInSecForIosWeb: 3,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
