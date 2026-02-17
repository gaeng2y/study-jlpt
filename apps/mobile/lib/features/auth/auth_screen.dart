import 'package:flutter/material.dart';

import '../../shared/app_state.dart';
import '../../shared/widgets/brand_mark.dart';
import '../../shared/widgets/glass_surface.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state});

  final AppState state;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE5EDFF), Color(0xFFF1F5FF), Color(0xFFDFFAF4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GlassSurface(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 14),
                          child: BrandMark(compact: true),
                        ),
                      ),
                      Text(
                        '로그인하고 진도를 저장하세요',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 8),
                      const Text('기기 변경 후에도 학습 기록을 이어갈 수 있습니다.'),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: widget.state.oauthInProgress
                            ? null
                            : () => _signIn(apple: false),
                        icon: const Icon(Icons.g_mobiledata),
                        label: const Text('Google로 계속하기'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: widget.state.oauthInProgress
                            ? null
                            : () => _signIn(apple: true),
                        icon: const Icon(Icons.apple),
                        label: const Text('Apple로 계속하기'),
                      ),
                      if (widget.state.oauthInProgress) ...[
                        const SizedBox(height: 12),
                        const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ],
                      if (widget.state.authErrorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.state.authErrorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn({required bool apple}) async {
    setState(() => _error = null);

    try {
      if (apple) {
        await widget.state.signInWithApple();
      } else {
        await widget.state.signInWithGoogle();
      }
    } catch (e) {
      setState(() {
        _error = '로그인 시도에 실패했습니다: $e';
      });
    }
  }
}
