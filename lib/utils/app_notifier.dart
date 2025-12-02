import 'package:flutter/material.dart';
import 'package:appwrite_flutter_starter_kit/config/network/network_error.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:appwrite_flutter_starter_kit/config/network/network_error.dart';

/// نوع توست‌های اپ
enum AppToastType {
  success,
  warning,
  error,
  info,
  delete,
}

/// نوتیفایر مرکزی برای نمایش پیام‌ها در اپ
class AppNotifier {
  const AppNotifier._();

  // یک توست در هر لحظه
  static Timer? _toastTimer;
  static OverlayEntry? _overlayEntry;

  // ----------------- API عمومی برای استفاده در اپ -----------------

  static void showSuccess(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      type: AppToastType.success,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      type: AppToastType.warning,
    );
  }

  static void showError(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      type: AppToastType.error,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      type: AppToastType.info,
    );
  }

  static void showDelete(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      type: AppToastType.delete,
    );
  }

  static void showNetworkError(BuildContext context, NetworkError error) {
    showError(context, error.userMessage);
  }

  // ----------------- پیاده‌سازی داخلی توست -----------------

  static void _showToast(
      BuildContext context, {
        required String message,
        required AppToastType type,
      }) {
    // اگر توست قبلی هنوز باز است، ببندش
    _toastTimer?.cancel();
    _toastTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _overlayEntry = _createOverlayEntry(
      context,
      message: message,
      type: type,
    );
    overlay.insert(_overlayEntry!);

    // زمان نمایش (کمی بیشتر از طول انیمیشن)
    _toastTimer = Timer(const Duration(seconds: 4), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  static OverlayEntry _createOverlayEntry(
      BuildContext context, {
        required String message,
        required AppToastType type,
      }) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    final Color bgColor;
    final IconData iconData;

    switch (type) {
      case AppToastType.success:
        bgColor = const Color(0xFF16A34A); // سبز
        iconData = Icons.check_circle_outline;
        break;
      case AppToastType.warning:
        bgColor = const Color(0xFFF59E0B); // نارنجی
        iconData = Icons.warning_amber_rounded;
        break;
      case AppToastType.error:
        bgColor = const Color(0xFFDC2626); // قرمز
        iconData = Icons.error_outline;
        break;
      case AppToastType.info:
        bgColor = const Color(0xFF2563EB); // آبی
        iconData = Icons.info_outline;
        break;
      case AppToastType.delete:
        bgColor = const Color(0xFF6B7280); // خاکستری
        iconData = Icons.delete_outline;
        break;
    }

    return OverlayEntry(
      builder: (context) => Positioned(
        // بالای صفحه
        top: mediaQuery.padding.top + 12,
        left: 100,
        right: 100,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SlideInToastMessageAnimation(
            child: Material(
              elevation: 10.0,
              borderRadius: BorderRadius.circular(10),
              color: Colors.transparent,
              child: Container(
                width: width - 20,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // متن
                    Expanded(
                      child: Text(
                        message,
                        textAlign: TextAlign.right,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // آیکن
                    Icon(
                      iconData,
                      color: Colors.white,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// انیمیشن اسلاید-این / اسلاید-اوت برای توست
class SlideInToastMessageAnimation extends StatefulWidget {
  final Widget child;

  const SlideInToastMessageAnimation({super.key, required this.child});

  @override
  State<SlideInToastMessageAnimation> createState() =>
      _SlideInToastMessageAnimationState();
}

class _SlideInToastMessageAnimationState
    extends State<SlideInToastMessageAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;

  @override
  void initState() {
    super.initState();

    const totalDuration = Duration(milliseconds: 1500);
    _controller = AnimationController(
      vsync: this,
      duration: totalDuration,
    );

    // توالی شبیه کدی که فرستادی:
    // 0-0.25s: از بالا به پایین و fade-in
    // 0.25-1.25s: ثابت
    // 1.25-1.5s: بالا رفتن و fade-out
    _translateY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: -100.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 250,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 1000,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -100.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 250,
      ),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 500,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 1000,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 500,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _translateY.value),
            child: child,
          ),
        );
      },
    );
  }
}
