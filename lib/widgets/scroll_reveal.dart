import 'package:flutter/material.dart';

/// Fades and slides a section up as it enters the screen — the same feel
/// as the on-scroll reveal animations on mustav.vercel.app's landing page.
/// Uses a VisibilityDetector-free approach: staggers on first build via
/// [delay], which reads naturally as each section "arriving" as the user
/// scrolls into the general area during first render, and always looks
/// intentional even on fast re-scrolls.
class ScrollReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const ScrollReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 550),
  });

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Visibility-aware variant for long scrolling pages: reveals a section the
/// first time it scrolls into the viewport, using a plain
/// NotificationListener so no extra package is required.
class VisibleOnceReveal extends StatefulWidget {
  final Widget child;
  const VisibleOnceReveal({super.key, required this.child});

  @override
  State<VisibleOnceReveal> createState() => _VisibleOnceRevealState();
}

class _VisibleOnceRevealState extends State<VisibleOnceReveal> {
  bool _revealed = false;
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Fix: pehle sirf scroll event pe visibility check hoti thi. Agar
    // ancestor rebuild ho (jaise location change hone pe), ye state fresh
    // ho jaati thi (_revealed=false) aur content invisible reh jata tha
    // jab tak dobara scroll na ho. Ab first frame ke turant baad bhi check
    // hoti hai.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_revealed && _checkVisible()) {
        setState(() => _revealed = true);
      }
    });
  }

  bool _checkVisible() {
    final ctx = _key.currentContext;
    if (ctx == null) return false;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return false;
    final position = box.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    return position.dy < screenHeight * 0.92;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!_revealed && _checkVisible()) {
          setState(() => _revealed = true);
        }
        return false;
      },
      child: Container(
        key: _key,
        child: _revealed || _checkVisible()
            ? ScrollReveal(child: widget.child)
            : Opacity(opacity: 0, child: widget.child),
      ),
    );
  }
}
