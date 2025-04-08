import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manassa_e_menu/models/user.dart';
import 'package:manassa_e_menu/services/auth_service.dart';
import 'package:manassa_e_menu/ui/widgets/app_drawer.dart';
import 'package:manassa_e_menu/utils.dart';

final _nameProvider = StateProvider((ref) => '');
final _usernameProvider = StateProvider((ref) => '');
final _passwordProvider = StateProvider((ref) => '');
final _confirmPasswordProvider = StateProvider((ref) => '');
final _isLogin = StateProvider((ref) => true);
final _isSignUp = StateProvider((ref) => !ref.watch(_isLogin));
final _isLoading = StateProvider((ref) => false);
final _obscurePassword = StateProvider((ref) => false);
final _errorMessage = StateProvider<String?>((ref) => null);

class LoginSignupScreen extends ConsumerStatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  ConsumerState<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends ConsumerState<LoginSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _validateFormInputs(WidgetRef ref) {
    final name = ref.watch(_nameProvider).trim();
    final username = ref.watch(_usernameProvider).trim();
    final password = ref.watch(_passwordProvider).trim();
    final confirmPassword = ref.watch(_confirmPasswordProvider).trim();

    if (ref.watch(_isLogin)) {
      return username.isNotEmpty && password.isNotEmpty;
    } else {
      return name.isNotEmpty && username.isNotEmpty && password == confirmPassword;
    }
  }

  void _toggleFormType() {
    ref.invalidate(_nameProvider);
    ref.invalidate(_usernameProvider);
    ref.invalidate(_passwordProvider);
    ref.invalidate(_confirmPasswordProvider);
    ref.read(_isLogin.notifier).state = !ref.read(_isLogin);
    ref.read(_isLoading.notifier).state = false;
    ref.read(_errorMessage.notifier).state = null;
    _formKey.currentState?.reset();
  }

  Future<void> _submitForm(BuildContext context, WidgetRef ref) async {
    // تحقق من صحة البيانات قبل المتابعة
    if (!_formKey.currentState!.validate()) {
      ref.read(_errorMessage.notifier).state = null;
      return;
    }

    ref.read(_isLoading.notifier).state = true;

    try {
      final isLogin = ref.read(_isLogin);
      final email = ref.read(_usernameProvider).trim();
      final password = ref.read(_passwordProvider).trim();
      final name = ref.read(_nameProvider).trim();

      final user = isLogin
          ? await AuthService.instance.signInWithEmailPassword(
              email: email,
              password: password,
            )
          : await AuthService.instance.signUpWithEmailPassword(
              name: name,
              email: email,
              password: password,
              restaurants: [],
              isAdmin: false,
            );

      if (!mounted) return;

      if (user != null) {
        ref.read(_errorMessage.notifier).state = null;
        // يمكنك الانتقال إلى الشاشة الرئيسية أو إعادة التوجيه هنا إن أردت
        // context.go('/'); مثلاً
      } else {
        ref.read(_errorMessage.notifier).state = 'فشل تسجيل الدخول، حاول مرة أخرى.';
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ref.read(_errorMessage.notifier).state = e.message ?? "حدث خطأ أثناء المصادقة.";
    } catch (e) {
      if (!mounted) return;
      ref.read(_errorMessage.notifier).state = "حدث خطأ غير متوقع. حاول مرة أخرى.";
      debugPrint("Unknown error: $e");
    } finally {
      if (mounted) {
        ref.read(_isLoading.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = ref.watch(_isLogin);
    final isLoading = ref.watch(_isLoading);
    final isValid = _validateFormInputs(ref);
    final errorMessage = ref.watch(_errorMessage);
    final obscurePassword = ref.watch(_obscurePassword);

    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'تسجيل الدخول' : 'تسجيل حساب جديد'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Utils.appName(context)),
                  const SizedBox(height: 24),
                  if (!isLogin)
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder()),
                      onChanged: (value) => ref.read(_nameProvider.notifier).state = value,
                      validator: (value) => value!.isEmpty ? 'يرجى إدخال الاسم' : null,
                    ),
                  if (!isLogin) const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'البريد/الهاتف', border: OutlineInputBorder()),
                    onChanged: (value) => ref.read(_usernameProvider.notifier).state = value,
                    validator: (value) {
                      if (value == null || (!Utils.emailRegex.hasMatch(value) && !Utils.phoneRegex.hasMatch(value))) {
                        return 'يرجى إدخال بريد إلكتروني أو رقم هاتف صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => ref.read(_obscurePassword.notifier).state = !obscurePassword,
                      ),
                    ),
                    onChanged: (value) => ref.read(_passwordProvider.notifier).state = value,
                    validator: (value) => value!.isEmpty ? 'يرجى إدخال كلمة المرور' : null,
                  ),
                  const SizedBox(height: 12),
                  if (!isLogin)
                    TextFormField(
                      obscureText: obscurePassword,
                      decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور', border: OutlineInputBorder()),
                      onChanged: (value) => ref.read(_confirmPasswordProvider.notifier).state = value,
                      validator: (value) => value != ref.read(_passwordProvider) ? 'كلمتا المرور غير متطابقتين' : null,
                    ),
                  if (!isLogin) const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: isLoading || !isValid ? null : () => _submitForm(context, ref),
                    child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isLogin ? 'تسجيل الدخول' : 'تسجيل'),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  TextButton(
                    onPressed: isLoading ? null : _toggleFormType,
                    child: Text(isLogin ? 'ليس لديك حساب؟ أنشئ واحدًا' : 'لديك حساب؟ تسجيل الدخول'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
