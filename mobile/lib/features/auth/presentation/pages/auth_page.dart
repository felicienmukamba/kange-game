import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/user_profile.dart';
import '../bloc/auth_bloc.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _obscure = true;
  UserRole _role = UserRole.player;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final bloc = context.read<AuthBloc>();
    if (_register) {
      bloc.add(AuthRegisterRequested(
        username: _username.text,
        email: _email.text,
        password: _password.text,
        role: _role,
      ));
    } else {
      bloc.add(AuthLoginRequested(_username.text, _password.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) => showSnack(context, state.error!, error: true),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: BlocBuilder<AuthBloc, AuthState>(
                  buildWhen: (a, b) => a.busy != b.busy || a.fieldErrors != b.fieldErrors,
                  builder: (context, state) => Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Logo(),
                        const SizedBox(height: 28),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('Connexion')),
                            ButtonSegment(value: true, label: Text('Inscription')),
                          ],
                          selected: {_register},
                          onSelectionChanged: (s) => setState(() => _register = s.first),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _username,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: InputDecoration(
                            labelText: 'Pseudo',
                            prefixIcon: const Icon(Icons.person_outline),
                            errorText: state.fieldErrors['username'],
                          ),
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.length < 3) return 'Au moins 3 caractères';
                            if (_register && !RegExp(r'^[A-Za-z0-9_]{3,20}$').hasMatch(s)) {
                              return 'Lettres, chiffres et _ uniquement (20 max)';
                            }
                            return null;
                          },
                        ),
                        if (_register) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: const Icon(Icons.alternate_email),
                              errorText: state.fieldErrors['email'],
                            ),
                            validator: (v) =>
                                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '') ? null : 'E-mail invalide',
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            errorText: state.fieldErrors['password'],
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v?.length ?? 0) < 6 ? 'Au moins 6 caractères' : null,
                        ),
                        if (_register) ...[
                          const SizedBox(height: 20),
                          Text('Je suis…', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final role in const [UserRole.player, UserRole.streamer, UserRole.creator])
                                ChoiceChip(
                                  label: Text('${role.emoji}  ${role.label}'),
                                  selected: _role == role,
                                  onSelected: (_) => setState(() => _role = role),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            switch (_role) {
                              UserRole.streamer => 'Lance des lives et joue avec ton audience.',
                              UserRole.creator => 'Crée tes challenges, quiz et cagnottes.',
                              _ => 'Joue, grimpe dans le classement, gagne des coins.',
                            },
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: state.busy ? null : _submit,
                          child: state.busy
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                              : Text(_register ? 'Créer mon compte' : 'Entrer dans l\'arène'),
                        ),
                        if (kDebugMode && !_register) ...[
                          const SizedBox(height: 16),
                          _DemoAccounts(onPick: (u, p) {
                            _username.text = u;
                            _password.text = p;
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 28)],
          ),
          child: const Text('⚡', style: TextStyle(fontSize: 38)),
        ),
        const SizedBox(height: 16),
        Text(Env.appName, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        const Text('1000 challenges · Multijoueur · Live', style: TextStyle(color: AppColors.textMuted)),
      ],
    );
  }
}

/// Seeded development accounts (see backend DataInitializer). Debug builds only.
class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.onPick});

  final void Function(String username, String password) onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        for (final (u, p) in const [('gamer_pro', 'gamer123'), ('stream_queen', 'stream123'), ('admin', 'admin123')])
          ActionChip(label: Text('Démo : $u'), onPressed: () => onPick(u, p)),
      ],
    );
  }
}
