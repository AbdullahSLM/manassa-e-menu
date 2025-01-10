import 'package:manassa_e_commerce/db/db.dart';
import 'package:manassa_e_commerce/ui/app.dart';
import 'package:manassa_e_commerce/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

var emailProvider = StateProvider((_) => '');
var passwordProvider = StateProvider((_) => '');

var emailErrorMsg = StateProvider<String?>((_) => null);
var passwordErrorMsg = StateProvider<String?>((_) => null);

var hidePassword = StateProvider((_) => true);

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('تسجيل الدخول'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Consumer(
                builder: (context, ref, child) {
                  return TextFormField(
                    onChanged: (value) => ref.read(emailProvider.notifier).state = value,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: const OutlineInputBorder(),
                      errorText: ref.watch(emailErrorMsg),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Consumer(
                builder: (context, ref, child) {
                  return TextFormField(
                    obscureText: ref.watch(hidePassword),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      border: const OutlineInputBorder(),
                      errorText: ref.watch(passwordErrorMsg),
                      suffixIcon: IconButton(
                        onPressed: () => ref.read(hidePassword.notifier).state = !ref.read(hidePassword),
                        icon: Icon(ref.watch(hidePassword) ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    onChanged: (value) => ref.read(passwordProvider.notifier).state = value,
                  );
                },
              ),
            ),
            const Spacer(),
            const Divider(height: 0, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () => login(context, ref),
                    child: const Text('تسجيل الدخول'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void login(BuildContext context, WidgetRef ref) async {
    ref.read(emailErrorMsg.notifier).state = null;
    ref.read(passwordErrorMsg.notifier).state = null;

    final email = ref.read(emailProvider);
    if (email.isEmpty) {
      ref.read(emailErrorMsg.notifier).state = 'يرجى إدخال البريد الإلكتروني';
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      ref.read(emailErrorMsg.notifier).state = 'الرجاء إدخال بريد إلكتروني صالح';
      return;
    }

    final password = ref.read(passwordProvider);
    if (password.isEmpty) {
      ref.read(passwordErrorMsg.notifier).state = 'يرجى إدخال كلمة المرور';
      return;
    }

    ref.read(currentUser.notifier).state = await Database.login(email, password);
    if (context.mounted) Navigator.pop(context);
  }
}
