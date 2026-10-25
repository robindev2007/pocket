import 'package:flutter/material.dart';

/// A standardized screen container that provides consistent padding,
/// optional scrolling, and responsive maximum-width centering for web and desktop.
class ScreenContainer extends StatelessWidget {
  const ScreenContainer({
    super.key,
    required this.child,
    this.isScrollable = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.maxWidth = 720,
    this.scrollController,
    this.physics = const BouncingScrollPhysics(),
  });

  /// The content to display inside this screen container.
  final Widget child;

  /// Whether the child should be wrapped in a [SingleChildScrollView].
  ///
  /// Set to `false` for screens that manage their own scrollable lists
  /// (e.g. screens containing an [Expanded] [ListView]).
  final bool isScrollable;

  /// The padding around the screen content.
  final EdgeInsetsGeometry padding;

  /// The maximum content width, centering content on large screens (tablets/web).
  final double maxWidth;

  /// Optional scroll controller when [isScrollable] is true.
  final ScrollController? scrollController;

  /// Scroll physics when [isScrollable] is true.
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (isScrollable) {
      content = SingleChildScrollView(
        controller: scrollController,
        physics: physics,
        padding: padding,
        child: content,
      );
    } else if (padding != EdgeInsets.zero) {
      content = Padding(
        padding: padding,
        child: content,
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      ),
    );
  }
}

