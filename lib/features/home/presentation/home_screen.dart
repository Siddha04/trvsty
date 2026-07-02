import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_constants.dart';
import '../../../models/enums.dart';
import '../../../routes/route_paths.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common_widgets.dart';
import '../../verification/presentation/controllers/verification_controller.dart';

/// Pixel-Perfect Image Match for the White Cards on Dark Background UI.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _startVerification(BuildContext context, WidgetRef ref, UserType type) {
    HapticFeedback.selectionClick();
    ref.read(verificationControllerProvider.notifier).start(type);
    context.push(RoutePaths.scanAadhaar);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Deep dark navy background from the image
    const backgroundColor = Color(0xFF1B1E2E); 

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      FadeInContainer(
                        delay: const Duration(milliseconds: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Verify with Confidence',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Run a complete background verification in minutes.',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // PRIMARY CARDS (Individual / Business)
                      FadeInContainer(
                        delay: const Duration(milliseconds: 200),
                        child: isMobile 
                          ? Column(
                              children: [
                                _PrimaryWhiteCard(
                                  icon: Icons.person,
                                  title: 'Individual',
                                  subtitle: 'Verify a person',
                                  onTap: () => _startVerification(context, ref, UserType.individual),
                                ),
                                const SizedBox(height: 16),
                                _PrimaryWhiteCard(
                                  icon: Icons.business,
                                  title: 'Business',
                                  subtitle: 'Verify an organisation',
                                  onTap: () => _startVerification(context, ref, UserType.business),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _PrimaryWhiteCard(
                                    icon: Icons.person,
                                    title: 'Individual',
                                    subtitle: 'Verify a person',
                                    onTap: () => _startVerification(context, ref, UserType.individual),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _PrimaryWhiteCard(
                                    icon: Icons.business,
                                    title: 'Business',
                                    subtitle: 'Verify an organisation',
                                    onTap: () => _startVerification(context, ref, UserType.business),
                                  ),
                                ),
                              ],
                            ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // SERVICES HEADER
                      FadeInContainer(
                        delay: const Duration(milliseconds: 300),
                        child: const Text(
                          'Services',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.5, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // SERVICE LIST (Full Width)
                      FadeInContainer(
                        delay: const Duration(milliseconds: 400),
                        child: Column(
                          children: [
                            _ServiceWhiteCard(
                              icon: Icons.qr_code_scanner,
                              title: 'Aadhaar Secure QR',
                              subtitle: 'Scan & verify a signed Aadhaar QR.',
                            ),
                            const SizedBox(height: 12),
                            _ServiceWhiteCard(
                              icon: Icons.face_retouching_natural,
                              title: 'Face Match',
                              subtitle: 'Match a live selfie to the Aadhaar photo.',
                            ),
                            const SizedBox(height: 12),
                            _ServiceWhiteCard(
                              icon: Icons.credit_card_outlined,
                              title: 'PAN Verification',
                              subtitle: 'Validate PAN and cross-check the name.',
                            ),
                            const SizedBox(height: 12),
                            _ServiceWhiteCard(
                              icon: Icons.gavel_outlined,
                              title: 'Criminal Record Check',
                              subtitle: 'Screen public court & criminal records.',
                            ),
                            const SizedBox(height: 12),
                            // DIGILOCKER WITH ARROW
                            _ServiceWhiteCard(
                              icon: Icons.folder_shared,
                              title: 'Connect DigiLocker — pull documents with your consent.',
                              subtitle: '', // No subtitle for this one in image
                              hasArrow: true,
                              onTap: () => context.push(RoutePaths.digilocker),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40), // Padding for bottom nav
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}

class _PremiumButtonBase extends StatefulWidget {
  const _PremiumButtonBase({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PremiumButtonBase> createState() => _PremiumButtonBaseState();
}

class _PremiumButtonBaseState extends State<_PremiumButtonBase> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) { _controller.reverse(); widget.onTap(); }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// The top Individual / Business cards with centered content.
class _PrimaryWhiteCard extends StatelessWidget {
  const _PrimaryWhiteCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PremiumButtonBase(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular Icon Container
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE0F7FA), // Very light cyan background
              ),
              child: Icon(icon, color: const Color(0xFF00B4D8), size: 28), // Bright cyan icon
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black, letterSpacing: -0.3),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF8B92A5), fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Service Cards (Toolbox) exactly matching the image.
class _ServiceWhiteCard extends StatelessWidget {
  const _ServiceWhiteCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.hasArrow = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool hasArrow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _PremiumButtonBase(
      onTap: onTap ?? () => HapticFeedback.selectionClick(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Bright cyan icon (no background container in the image for services)
            Icon(icon, color: const Color(0xFF00B4D8), size: 26),
            const SizedBox(width: 20),
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: subtitle.isEmpty ? FontWeight.w500 : FontWeight.w700, 
                      fontSize: 15, 
                      color: Colors.black, 
                      letterSpacing: -0.3
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF8B92A5), fontSize: 13, fontWeight: FontWeight.w400),
                    ),
                  ],
                ],
              ),
            ),
            if (hasArrow) ...[
              const SizedBox(width: 16),
              const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}
