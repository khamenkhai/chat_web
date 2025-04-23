import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final Color? bubbleColor;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? textStyle;
  final Widget? tail;
  final Widget? leading;
  final Widget? trailing;
  final BoxConstraints? constraints;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    this.isMe = false,
    this.bubbleColor,
    this.textColor,
    this.borderRadius = 12.0,
    this.padding,
    this.margin,
    this.textStyle,
    this.tail,
    this.leading,
    this.trailing,
    this.constraints,
    this.shadow,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final defaultBubbleColor = isMe
        ? (isDarkMode ? Colors.blue[700]! : Colors.blue[500]!)
        : (isDarkMode ? Colors.grey[800]! : Colors.grey[200]!);

    final defaultTextColor = isMe
        ? Colors.white
        : (isDarkMode ? Colors.white : Colors.black);

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      constraints: constraints,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe && leading != null) leading!,
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Material(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadius),
                    topRight: Radius.circular(borderRadius),
                    bottomLeft: Radius.circular(isMe ? borderRadius : 0),
                    bottomRight: Radius.circular(isMe ? 0 : borderRadius),
                  ),
                  elevation: shadow != null ? 0 : 1,
                  shadowColor: shadow != null ? null : Colors.black26,
                  color: bubbleColor ?? defaultBubbleColor,
                  child: InkWell(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      topRight: Radius.circular(borderRadius),
                      bottomLeft: Radius.circular(isMe ? borderRadius : 0),
                      bottomRight: Radius.circular(isMe ? 0 : borderRadius),
                    ),
                    onTap: onTap,
                    onLongPress: onLongPress,
                    child: Container(
                      padding: padding ??
                          const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(borderRadius),
                          topRight: Radius.circular(borderRadius),
                          bottomLeft: Radius.circular(isMe ? borderRadius : 0),
                          bottomRight: Radius.circular(isMe ? 0 : borderRadius),
                        ),
                        boxShadow: shadow,
                      ),
                      child: Text(
                        message,
                        style: textStyle ??
                            TextStyle(
                              color: textColor ?? defaultTextColor,
                              fontSize: 16,
                            ),
                      ),
                    ),
                  ),
                ),
                if (tail != null) tail!,
              ],
            ),
          ),
          if (isMe && trailing != null) trailing!,
        ],
      ),
    );
  }
}