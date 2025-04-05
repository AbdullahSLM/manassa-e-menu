import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manassa_e_menu/models/user.dart';
import 'package:manassa_e_menu/services/auth_service.dart';

// Import your user model if needed elsewhere, but not directly here now
// import 'package:manassa_e_menu/models/user.dart';
// Assuming Utils.appName exists
import 'package:manassa_e_menu/utils.dart'; // Adjust path

final _nameProvider = StateProvider((ref) => '');
final _usernameProvider = StateProvider((ref) => '');
final _passwordProvider = StateProvider((ref) => '');
final _confirmPasswordProvider = StateProvider((ref) => '');

final _isLogin = StateProvider((ref) => true);
final _isSignUp = StateProvider((ref) => !ref.watch(_isLogin));
final _isLoading = StateProvider((ref) => false);
final _obscurePassword = StateProvider((ref) => false);
final _errorMessage = StateProvider<String?>((ref) => null);
final _formKey = GlobalKey<FormState>();

class LoginSignupScreen extends ConsumerWidget {
  const LoginSignupScreen({super.key});

  // Function to check if inputs meet basic criteria (for button enabling)
  bool _validateFormInputs(WidgetRef ref) {
    final name = ref.watch(_nameProvider).trim();
    final username = ref.watch(_usernameProvider).trim();
    final password = ref.watch(_passwordProvider).trim();
    final confirmPassword = ref.watch(_confirmPasswordProvider).trim();

    var isValid = username.isNotEmpty && password.isNotEmpty;

    // TODO: check email/phone format for username

    if (isValid && ref.read(_isSignUp)) {
      // Sign up validation: name, username, password, confirm non-empty
      // and passwords match (basic checks)
      isValid &= name.isNotEmpty && password == confirmPassword;
    }

    return isValid;
  }

  void _toggleFormType(WidgetRef ref) {
    ref.read(_nameProvider.notifier).state = '';
    ref.read(_usernameProvider.notifier).state = '';
    ref.read(_passwordProvider.notifier).state = '';
    ref.read(_confirmPasswordProvider.notifier).state = '';

    ref.read(_isLogin.notifier).state = ref.read(_isSignUp);
    ref.read(_isLoading.notifier).state = false;
    ref.read(_errorMessage.notifier).state = null;

    _formKey.currentState?.reset(); // Reset form validation state
  }

  Future<void> _submitForm(BuildContext context, WidgetRef ref) async {
    // Trigger final form validation
    if (!_validateFormInputs(ref)) {
      // Update button state if validation fails explicitly here
      ref.read(_errorMessage.notifier).state = null;
      return;
    }
    // No need for _formKey.currentState!.save(); unless using onSaved

    ref.read(_isLoading.notifier).state = true;

    try {
      final UserModel? user;
      if (ref.read(_isLogin)) {
        user = await AuthService.instance.signInWithEmailPassword(
          email: ref.read(_usernameProvider).trim(),
          password: ref.read(_passwordProvider).trim(),
        );
      } else {
        // Passwords already validated by _formKey.currentState!.validate()
        user = await AuthService.instance.signUpWithEmailPassword(
          name: ref.read(_nameProvider).trim(),
          email: ref.read(_usernameProvider).trim(),
          password: ref.read(_passwordProvider).trim(),
          restaurants: [],
          isAdmin: false,
        );
      }

      if (user != null) {
        print("Auth successful for UID: ${user.uid}. Navigating...");
      } else {
        // This might indicate a delay in auth state propagation or an issue.
        print("WARN: Auth call succeeded but auth state not updated immediately.");
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) ref.read(_errorMessage.notifier).state = e.message ?? "An authentication error occurred.";
      print("FirebaseAuthException during submit: $e");
    } catch (e) {
      if (context.mounted) ref.read(_errorMessage.notifier).state = "An unexpected error occurred. Please try again.";
      print("Generic error during submit: $e");
    } finally {
      if (context.mounted) ref.read(_isLoading.notifier).state = false;
    }
  }

  @override
  Widget build(context, ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ref.watch(_isLogin) ? 'Login' : 'Sign Up'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            // onChanged: _validateFormInputs, // Alternative to listeners
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300), // Slightly wider
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0), // Add spacing
                        child: Utils.appName,
                      ),
                    ),

                    // --- Name Field (Sign Up Only) ---
                    if (ref.watch(_isSignUp))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TextFormField(
                          autofocus: ref.watch(_isSignUp),
                          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Name'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                          onChanged: (value) => ref.read(_nameProvider.notifier).state = value,
                          onFieldSubmitted: (value) => _formKey.currentState?.validate(),
                        ),
                      ),

                    // --- Email Field ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextFormField(
                        autofocus: ref.watch(_isLogin),
                        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Email/Phone Number'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && !Utils.emailRegex.hasMatch(value) && !Utils.phoneRegex.hasMatch(value)) {
                            return 'Please enter a valid email/phone address';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                        onChanged: (value) => ref.read(_usernameProvider.notifier).state = value,
                        onEditingComplete: () => _formKey.currentState?.validate(),
                      ),
                    ),

                    // --- Password Field ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final obscurePassword = ref.watch(_obscurePassword);
                          return TextFormField(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'Password',
                              suffixIcon: ExcludeFocus(
                                child: IconButton(
                                  icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                  onPressed: () => ref.read(_obscurePassword.notifier).state = !obscurePassword,
                                ),
                              ),
                            ),
                            obscureText: obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              return null;
                            },
                            textInputAction: ref.watch(_isLogin) ? TextInputAction.done : TextInputAction.next,
                            onChanged: (value) => ref.read(_passwordProvider.notifier).state = value,
                            onFieldSubmitted: (value) => _formKey.currentState?.validate(),
                          );
                        },
                      ),
                    ),

                    // --- Confirm Password Field (Sign Up Only) ---
                    if (ref.watch(_isSignUp))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final obscurePassword = ref.watch(_obscurePassword);
                            return TextFormField(
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Confirm Password',
                                suffixIcon: ExcludeFocus(
                                  child: IconButton(
                                    icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                    onPressed: () => ref.read(_obscurePassword.notifier).state = !obscurePassword,
                                  ),
                                ),
                              ),
                              obscureText: obscurePassword,
                              validator: (value) {
                                if (value != ref.read(_passwordProvider)) {
                                  return 'Passwords not match';
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.done,
                              onChanged: (value) => ref.read(_confirmPasswordProvider.notifier).state = value,
                              onFieldSubmitted: (value) => _formKey.currentState?.validate(),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 20), // Adjusted spacing

                    // --- Submit Button ---
                    Consumer(
                      builder: (context, ref, child) {
                        final isLoading = ref.watch(_isLoading);
                        final isValid = _validateFormInputs(ref);
                        return ElevatedButton(
                          // Disable button if loading or form is not potentially valid
                          onPressed: isLoading || !isValid ? null : () => _submitForm(context, ref),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12), // Button padding
                            // Grey out button when disabled
                            backgroundColor: isLoading || !isValid ? Colors.grey.shade400 : Theme.of(context).primaryColor,
                            foregroundColor: Colors.white, // Text color
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                (ref.watch(_isLogin) ? 'Login' : 'Sign Up') + (isValid ? '' : '!!!'),
                                style: const TextStyle(fontSize: 16),
                              ),
                              if (isLoading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                    // --- Error Message ---
                    Consumer(
                      builder: (context, ref, child) {
                        if (ref.watch(_errorMessage) == null) return Container();

                        return Padding(
                          padding: const EdgeInsets.only(top: 24.0), // Increased spacing
                          child: Text(
                            ref.watch(_errorMessage)!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24), // Adjusted spacing

                    // --- Toggle Button ---
                    Consumer(
                      builder: (context, ref, child) {
                        return TextButton(
                          onPressed: ref.watch(_isLoading) ? null : () => _toggleFormType(ref), // Disable toggle when loading
                          child: Text(
                            ref.watch(_isLogin) ? 'Don\'t have an account? Sign Up' : 'Already have an account? Login',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
