import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final IconData? icon;
  final double fontSize;
  final FontWeight fontWeight;
  final Border? border;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 56,
    this.borderRadius = 12,
    this.padding,
    this.gradient,
    this.icon,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = isEnabled && !isLoading && onPressed != null;
    
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: enabled ? gradient : null,
        color: gradient == null 
            ? (enabled 
                ? (backgroundColor ?? AppColors.primaryColor)
                : AppColors.textLight)
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: enabled ? [
          BoxShadow(
            color: (backgroundColor ?? AppColors.primaryColor).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        textColor ?? Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else if (icon != null) ...[
                  Icon(
                    icon,
                    color: textColor ?? Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                
                Text(
                  isLoading ? 'Loading...' : text,
                  style: TextStyle(
                    color: enabled 
                        ? (textColor ?? Colors.white)
                        : AppColors.textSecondary,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? borderColor;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;
  final double fontSize;
  final FontWeight fontWeight;

  const CustomOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.borderColor,
    this.textColor,
    this.width,
    this.height = 56,
    this.borderRadius = 12,
    this.padding,
    this.icon,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = isEnabled && !isLoading && onPressed != null;
    
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: enabled 
              ? (borderColor ?? AppColors.primaryColor)
              : AppColors.borderColor,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        borderColor ?? AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else if (icon != null) ...[
                  Icon(
                    icon,
                    color: enabled 
                        ? (textColor ?? borderColor ?? AppColors.primaryColor)
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                
                Text(
                  isLoading ? 'Loading...' : text,
                  style: TextStyle(
                    color: enabled 
                        ? (textColor ?? borderColor ?? AppColors.primaryColor)
                        : AppColors.textSecondary,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}