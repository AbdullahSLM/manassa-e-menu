import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manassa_dropdown_field/manassa_dropdown_field.dart';
import 'package:manassa_e_menu/models/restaurant.dart';
import 'package:manassa_e_menu/models/user.dart';
import 'package:manassa_e_menu/providers/users_providers.dart';
import 'package:manassa_e_menu/services/auth_service.dart';
import 'package:manassa_e_menu/utils.dart';

final _nameProvider = StateProvider((ref) => '');
final _usernameProvider = StateProvider((ref) => '');
final _passwordProvider = StateProvider((ref) => '');
final _confirmPasswordProvider = StateProvider((ref) => '');
final _restaurantsProvider = StateProvider((ref) => <Restaurant>[]);
final _isAdminProvider = StateProvider((ref) => false);

final _isLogin = StateProvider((ref) => true);
final _isSignUp = StateProvider((ref) => !ref.watch(_isLogin));
final _isLoading = StateProvider((ref) => false);
final _obscurePassword = StateProvider((ref) => false);
final _errorMessage = StateProvider<String?>((ref) => null);
final _formKey = GlobalKey<FormState>();

class AddEditUserScreen extends ConsumerStatefulWidget {
  final UserModel? userModel;

  const AddEditUserScreen({super.key, this.userModel});

  @override
  ConsumerState<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends ConsumerState<AddEditUserScreen> {
  late final bool isEdit;
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    isEdit = widget.userModel != null;

    _nameController = TextEditingController(text: widget.userModel?.name ?? '');
    _usernameController = TextEditingController(text: widget.userModel?.username ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      ref.read(_nameProvider.notifier).state = _nameController.text;
      ref.read(_usernameProvider.notifier).state = _usernameController.text;
      ref.read(_restaurantsProvider.notifier).state = widget.userModel?.restaurants ?? [];
      ref.read(_isAdminProvider.notifier).state = widget.userModel?.isAdmin ?? false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateFormInputs(WidgetRef ref) {
    final name = ref.watch(_nameProvider).trim();
    final username = ref.watch(_usernameProvider).trim();
    final password = ref.watch(_passwordProvider).trim();
    final confirmPassword = ref.watch(_confirmPasswordProvider).trim();
    // final isSignUp = ref.read(_isSignUp);

    if (isEdit) {
      return name.isNotEmpty && username.isNotEmpty;
    }

    final isValidLogin = username.isNotEmpty && password.isNotEmpty;
    final isValidSignUp = username.isNotEmpty && name.isNotEmpty && password == confirmPassword;

    return ref.read(_isLogin) ? isValidLogin : isValidSignUp;
  }

  void _toggleFormType(WidgetRef ref) {
    ref.read(_nameProvider.notifier).state = '';
    ref.read(_usernameProvider.notifier).state = '';
    ref.read(_passwordProvider.notifier).state = '';
    ref.read(_confirmPasswordProvider.notifier).state = '';
    ref.read(_restaurantsProvider.notifier).state = [];
    ref.read(_isAdminProvider.notifier).state = false;

    ref.read(_isLogin.notifier).state = ref.read(_isSignUp);
    ref.read(_isLoading.notifier).state = false;
    ref.read(_errorMessage.notifier).state = null;

    _formKey.currentState?.reset();
  }

  Future<void> _submitForm(BuildContext context, WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) {
      ref.read(_errorMessage.notifier).state = null;
      return;
    }

    ref.read(_isLoading.notifier).state = true;

    try {
      final name = ref.read(_nameProvider).trim();
      final username = ref.read(_usernameProvider).trim();
      final restaurants = ref.read(_restaurantsProvider);
      final isAdmin = ref.read(_isAdminProvider);

      if (isEdit) {
        final updatedUser = UserModel(
          uid: widget.userModel!.uid,
          name: name,
          username: username,
          restaurants: restaurants,
          isAdmin: isAdmin,
        );
        await AuthService.instance.updateUserProfile(updatedUser.uid, updatedUser.toJson());
      } else {
        final password = ref.read(_passwordProvider).trim();

        await AuthService.instance.signUpWithEmailPassword(
          name: name,
          email: username,
          password: password,
          restaurants: restaurants,
          isAdmin: isAdmin,
        );

        ref.invalidate(_nameProvider);
        ref.invalidate(_usernameProvider);
        ref.invalidate(_passwordProvider);
        ref.invalidate(_confirmPasswordProvider);
        ref.invalidate(_restaurantsProvider);
        ref.invalidate(_isAdminProvider);
      }

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ref.read(_errorMessage.notifier).state = 'حدث خطأ أثناء ${isEdit ? 'التحديث' : 'التسجيل'}.';
      }
    } finally {
      if (context.mounted) ref.read(_isLoading.notifier).state = false;
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تحديث' : (ref.watch(_isLogin) ? 'تسجيل الدخول' : 'تسجيل')),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Utils.appName,
                      ),
                    ),
                    if (isEdit || ref.watch(_isSignUp))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Name'),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your name' : null,
                          textInputAction: TextInputAction.next,
                          onChanged: (value) => ref.read(_nameProvider.notifier).state = value,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Email/Phone Number'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                        value != null && !Utils.emailRegex.hasMatch(value) && !Utils.phoneRegex.hasMatch(value)
                            ? 'Please enter a valid email/phone address'
                            : null,
                        textInputAction: TextInputAction.next,
                        onChanged: (value) => ref.read(_usernameProvider.notifier).state = value,
                      ),
                    ),
                    if (!isEdit)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Consumer(
                          builder: (context, ref, _) {
                            final obscurePassword = ref.watch(_obscurePassword);
                            return TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Password',
                                suffixIcon: IconButton(
                                  icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => ref.read(_obscurePassword.notifier).state = !obscurePassword,
                                ),
                              ),
                              obscureText: obscurePassword,
                              validator: (value) => value == null || value.isEmpty ? 'Please enter a password' : null,
                              textInputAction: TextInputAction.next,
                              onChanged: (value) => ref.read(_passwordProvider.notifier).state = value,
                            );
                          },
                        ),
                      ),
                    if (!isEdit && ref.watch(_isSignUp))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Consumer(
                          builder: (context, ref, _) {
                            final obscurePassword = ref.watch(_obscurePassword);
                            return TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Confirm Password',
                                suffixIcon: IconButton(
                                  icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => ref.read(_obscurePassword.notifier).state = !obscurePassword,
                                ),
                              ),
                              obscureText: obscurePassword,
                              validator: (value) => value != ref.read(_passwordProvider) ? 'Passwords not match' : null,
                              textInputAction: TextInputAction.done,
                              onChanged: (value) => ref.read(_confirmPasswordProvider.notifier).state = value,
                            );
                          },
                        ),
                      ),
                    Consumer(
                      builder: (context, ref, _) {
                        final restaurantsAsync = ref.watch(restaurantsProvider);
                        final selectedRestaurants = ref.watch(_restaurantsProvider);
                        return restaurantsAsync.when(
                          data: (items) {
                            final initialSelected = items
                                .asMap()
                                .entries
                                .where((entry) =>
                                selectedRestaurants.any((r) => r.id == entry.value.id))
                                .map((entry) => entry.key);
                            return DropdownField<Restaurant>(
                              isDense: true,
                              refreshDropdownMenuItemsOnChange: true,
                              items: items,
                              initialSelected: initialSelected,
                              multiselect: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'المطاعم',
                              ),
                              onChanged: (selectedIndexes) {
                                final selected = selectedIndexes.map((i) => items[i]).toList();
                                ref.read(_restaurantsProvider.notifier).state = selected;
                              },
                              childBuilder: (context, selected, selectedIndexes) {
                                if (selectedIndexes.isEmpty) return const Text('اختر مطعمًا واحدًا أو أكثر');
                                if (selectedIndexes.length == 1) {
                                  return Text(selected.elementAt(selectedIndexes.single).name);
                                }
                                return Text('${selectedIndexes.length} تم اختيارهم');
                              },
                              itemBuilder: (context, restaurant, index, selected) {
                                return ListTile(selected: selected, title: Text(restaurant.name));
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('فشل تحميل المطاعم: $e'),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
                      child: Row(
                        children: [
                          Consumer(
                            builder: (context, ref, _) {
                              return Switch(
                                value: ref.watch(_isAdminProvider),
                                onChanged: (val) => ref.read(_isAdminProvider.notifier).state = val,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          const Text('مدير'),
                        ],
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final isLoading = ref.watch(_isLoading);
                        final isValid = _validateFormInputs(ref);
                        return ElevatedButton(
                          onPressed: isLoading || !isValid ? null : () => _submitForm(context, ref),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isEdit
                                    ? 'تحديث'
                                    : (ref.watch(_isLogin) ? 'تسجيل الدخول' : 'تسجيل') + (isValid ? '' : '!!!'),
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
                    Consumer(
                      builder: (context, ref, _) {
                        final errorMessage = ref.watch(_errorMessage);
                        if (errorMessage == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: Text(
                            errorMessage,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    if (!isEdit)
                      Consumer(
                        builder: (context, ref, _) {
                          return TextButton(
                            onPressed: ref.watch(_isLoading) ? null : () => _toggleFormType(ref),
                            child: Text(
                              ref.watch(_isLogin)
                                  ? 'Don\'t have an account? Sign Up'
                                  : 'Already have an account? Login',
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
