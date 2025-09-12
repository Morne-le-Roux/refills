import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final IconThemeData? iconTheme;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 4.0,
    this.iconTheme,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      color: backgroundColor,
      child: SizedBox(
        height: kToolbarHeight,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (title != null) Center(child: title!),
            if (iconTheme != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: IconTheme(
                  data: iconTheme!,
                  child: const SizedBox.shrink(),
                ),
              ),
            if (actions != null)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
              ),
          ],
        ),
      ),
    );
  }
}
