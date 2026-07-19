import 'package:flutter/material.dart';

/// A seamless, infinitely-scrolling horizontal ticker — matches the
/// marquee bands on mustav.vercel.app ("SMASHED • FRESH • BOLD • CRAVE •"
/// and "MUSTAV • BURGERS •"). Duplicates the text run twice back-to-back
/// and shifts it left forever, wrapping with no visible seam.
class MarqueeTicker extends StatefulWidget {
  final String text;
  final Duration duration;
  final TextStyle? style;
  final Color? backgroundColor;
  final double verticalPadding;

  const MarqueeTicker({
    super.key,
    required this.text,
    this.duration = const Duration(seconds: 14),
    this.style,
    this.backgroundColor,
    this.verticalPadding = 12,
  });

  @override
  State<MarqueeTicker> createState() => _MarqueeTickerState();
}

class _MarqueeTickerState extends State<MarqueeTicker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.style ??
        const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 1.2);

    final span = TextSpan(text: '${widget.text}  ', style: textStyle);
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
    final segmentWidth = painter.width;

    return Container(
      color: widget.backgroundColor,
      padding: EdgeInsets.symmetric(vertical: widget.verticalPadding),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = -_controller.value * segmentWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Transform.translate(
                offset: Offset(offset, 0),
                // Three repeats guarantee the viewport is always fully
                // covered regardless of screen width.
                child: Row(children: [for (var i = 0; i < 3; i++) Text('${widget.text}  ', style: textStyle)]),
              ),
            );
          },
        ),
      ),
    );
  }
}
