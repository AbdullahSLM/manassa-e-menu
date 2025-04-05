import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manassa_dropdown_field/manassa_dropdown_field.dart'; // تأكد من أن اسم الحزمة صحيح
import 'package:manassa_e_menu/models/restaurant.dart';
import 'package:manassa_e_menu/models/user.dart';
import 'package:manassa_e_menu/providers/users_providers.dart';
import 'package:manassa_e_menu/services/auth_service.dart';
import 'package:manassa_e_menu/utils.dart';

// --- Providers (بدون تغيير) ---
final _nameProvider = StateProvider((ref) => '');
final _usernameProvider = StateProvider((ref) => '');
final _passwordProvider = StateProvider((ref) => '');
final _confirmPasswordProvider = StateProvider((ref) => '');
// Provider للمطاعم المختارة حالياً للمستخدم
final _selectedRestaurantsProvider = StateProvider((ref) => <Restaurant>[]);
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

    // استخدام addPostFrameCallback لضمان أن الـ BuildContext متاح
    // ولتحديث حالة Riverpod بعد بناء الإطار الأول
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // تأكد من أن الـ widget ما زال mounted قبل الوصول لـ ref
      if (mounted) {
        ref.read(_nameProvider.notifier).state = _nameController.text;
        ref.read(_usernameProvider.notifier).state = _usernameController.text;
        // تحديث provider المطاعم المختارة
        ref.read(_selectedRestaurantsProvider.notifier).state = widget.userModel?.restaurants ?? [];
        ref.read(_isAdminProvider.notifier).state = widget.userModel?.isAdmin ?? false;
      }
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

  // هذه الدالة قد لا تكون ضرورية إذا كانت الصفحة فقط للإضافة/التعديل
  // وليس للتبديل بين تسجيل الدخول والتسجيل
  void _toggleFormType(WidgetRef ref) {
    // ... (الكود الأصلي لمسح الحقول وتبديل الحالة) ...
    // تأكد من مسح _selectedRestaurantsProvider أيضاً
    ref.read(_selectedRestaurantsProvider.notifier).state = [];
    ref.read(_isAdminProvider.notifier).state = false;
    ref.read(_isLogin.notifier).state = ref.read(_isSignUp); // تبديل الحالة
    ref.read(_isLoading.notifier).state = false;
    ref.read(_errorMessage.notifier).state = null;

    _formKey.currentState?.reset(); // إعادة تعيين الفورم
    // قد تحتاج أيضاً لمسح الـ Controllers يدوياً
    _nameController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    // إعادة تعيين حالة الـ Providers المرتبطة بـ Controllers
    ref.invalidate(_nameProvider);
    ref.invalidate(_usernameProvider);
    ref.invalidate(_passwordProvider);
    ref.invalidate(_confirmPasswordProvider);
  }

  Future<void> _submitForm(BuildContext context, WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) {
      ref.read(_errorMessage.notifier).state = null; // مسح أي خطأ سابق
      return;
    }

    ref.read(_isLoading.notifier).state = true;
    ref.read(_errorMessage.notifier).state = null; // مسح رسالة الخطأ عند البدء

    try {
      final name = ref.read(_nameProvider).trim();
      final username = ref.read(_usernameProvider).trim();
      // استخدام provider المطاعم المختارة
      final restaurants = ref.read(_selectedRestaurantsProvider);
      final isAdmin = ref.read(_isAdminProvider);

      if (isEdit) {
        // --- تحديث المستخدم ---
        final updatedUser = UserModel(
          uid: widget.userModel!.uid,
          // استخدم UID الموجود
          name: name,
          username: username,
          // عادة لا يتم تحديث الايميل/رقم الهاتف بسهولة بعد الإنشاء بسبب المصادقة
          restaurants: restaurants,
          isAdmin: isAdmin,
        );
        // استدعاء دالة التحديث (تأكد من أنها تحدث البيانات في Firestore/Database وليس فقط Auth profile)
        await AuthService.instance.updateUserProfile(updatedUser.uid, updatedUser.toJson());
        // يمكنك إضافة تحديث كلمة المرور كعملية منفصلة إذا لزم الأمر
      } else {
        // --- إنشاء مستخدم جديد ---
        final password = ref.read(_passwordProvider).trim();

        // استخدام دالة التسجيل التي تنشئ المستخدم في Auth وتخزن بياناته في Firestore
        await AuthService.instance.signUpWithEmailPassword(
          name: name,
          email: username,
          // يجب أن يكون ايميل صالح
          password: password,
          restaurants: restaurants,
          isAdmin: isAdmin,
        );

        // لا حاجة لـ invalidate هنا لأننا سنغلق الصفحة
      }

      // تحديث قائمة المستخدمين الإجمالية في الـ provider الرئيسي (إذا لزم الأمر)
      // ref.refresh(allUsersProvider); أو أي provider مشابه تستخدمه لعرض قائمة المستخدمين

      if (context.mounted) Navigator.pop(context); // العودة للشاشة السابقة بعد النجاح
    } on FirebaseAuthException catch (e) {
      // التعامل مع أخطاء المصادقة بشكل خاص
      String message = 'حدث خطأ ما.';
      if (e.code == 'weak-password') {
        message = 'كلمة المرور ضعيفة جدًا.';
      } else if (e.code == 'email-already-in-use') {
        message = 'هذا البريد الإلكتروني مستخدم بالفعل.';
      } else if (e.code == 'invalid-email') {
        message = 'البريد الإلكتروني غير صالح.';
      }
      // أضف المزيد من حالات الخطأ حسب الحاجة
      if (context.mounted) {
        ref.read(_errorMessage.notifier).state = message;
      }
    } catch (e) {
      // التعامل مع الأخطاء العامة
      if (context.mounted) {
        ref.read(_errorMessage.notifier).state = 'حدث خطأ غير متوقع أثناء ${isEdit ? 'التحديث' : 'التسجيل'}.';
        // يمكنك طباعة الخطأ للمساعدة في التصحيح
        // print('Submit Error: $e');
      }
    } finally {
      // التأكد من أن الـ widget ما زال mounted قبل تحديث الحالة
      if (mounted) {
        ref.read(_isLoading.notifier).state = false;
      }
    }
  }

  // --- بناء الواجهة (مع التعديل في الـ DropdownField) ---
  @override
  Widget build(context) {
    // الاستماع للتغيرات في loading و errorMessage لإعادة بناء الواجهة عند الحاجة
    ref.watch(_isLoading);
    ref.watch(_errorMessage);

    // تحديد عنوان الصفحة بناءً على الحالة
    String pageTitle = isEdit ? 'تعديل المستخدم' : 'إضافة مستخدم جديد';
    // إذا كانت الصفحة تستخدم أيضاً للتبديل بين تسجيل الدخول والتسجيل
    // if (!isEdit) {
    //   pageTitle = ref.watch(_isLogin) ? 'تسجيل الدخول' : 'تسجيل مستخدم جديد';
    // }

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
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
                constraints: const BoxConstraints(maxWidth: 400), // يمكن زيادة العرض قليلاً
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Utils.appName, // تأكد من أن هذا يعرض شيئًا مناسبًا
                      ),
                    ),

                    // حقل الاسم (يظهر دائماً في الإضافة والتعديل)
                    // if (isEdit || ref.watch(_isSignUp)) // الشرط الأصلي قد لا يكون دقيقاً
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'الاسم الكامل', // تعديل النص بالعربية
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'الرجاء إدخال الاسم' : null,
                        textInputAction: TextInputAction.next,
                        onChanged: (value) => ref.read(_nameProvider.notifier).state = value,
                      ),
                    ),

                    // حقل الايميل/رقم الهاتف
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'البريد الإلكتروني', // أو 'البريد أو رقم الهاتف'
                          prefixIcon: Icon(Icons.email_outlined),
                          // تعطيل الحقل في وضع التعديل إذا كنت لا تريد السماح بتغيير الايميل
                          // enabled: !isEdit,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        // تعطيل التحقق من الصحة إذا كان الحقل معطلاً
                        validator: (value) {
                          // if (!isEdit) { // فقط التحقق في حالة الإضافة
                          if (value == null || value.trim().isEmpty) {
                            return 'الرجاء إدخال البريد الإلكتروني';
                          }
                          if (!Utils.emailRegex.hasMatch(value.trim())) {
                            return 'صيغة البريد الإلكتروني غير صحيحة';
                          }
                          // }
                          // يمكنك إضافة تحقق لرقم الهاتف هنا إذا لزم الأمر
                          // else if (!Utils.phoneRegex.hasMatch(value.trim())) { ... }
                          return null; // صالح
                        },
                        textInputAction: TextInputAction.next,
                        onChanged: (value) => ref.read(_usernameProvider.notifier).state = value,
                        // قراءة فقط في وضع التعديل إذا لزم الأمر
                        // readOnly: isEdit,
                      ),
                    ),

                    // حقول كلمة المرور (تظهر فقط في وضع الإضافة)
                    // أو يمكن عرض حقل "تغيير كلمة المرور" في وضع التعديل بشكل منفصل
                    if (!isEdit) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Consumer(
                          // استخدم Consumer للوصول لـ _obscurePassword
                          builder: (context, ref, _) {
                            final obscure = ref.watch(_obscurePassword);
                            return TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'كلمة المرور',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => ref.read(_obscurePassword.notifier).state = !obscure,
                                ),
                              ),
                              obscureText: obscure,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال كلمة المرور';
                                }
                                if (value.length < 6) {
                                  return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                              onChanged: (value) => ref.read(_passwordProvider.notifier).state = value,
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Consumer(
                          // استخدم Consumer مرة أخرى
                          builder: (context, ref, _) {
                            final obscure = ref.watch(_obscurePassword);
                            return TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'تأكيد كلمة المرور',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => ref.read(_obscurePassword.notifier).state = !obscure,
                                ),
                              ),
                              obscureText: obscure,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء تأكيد كلمة المرور';
                                }
                                if (value != ref.read(_passwordProvider)) {
                                  return 'كلمتا المرور غير متطابقتين';
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.done,
                              // آخر حقل قبل الـ dropdown
                              onChanged: (value) => ref.read(_confirmPasswordProvider.notifier).state = value,
                            );
                          },
                        ),
                      ),
                    ], // نهاية حقول كلمة المرور الشرطية

                    // --- DropdownField للمطاعم (مع التعديل) ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Consumer(
                        builder: (context, ref, _) {
                          // مراقبة provider قائمة المطاعم الكاملة
                          final restaurantsAsync = ref.watch(restaurantsProvider);
                          // مراقبة provider المطاعم المختارة حالياً للمستخدم
                          final selectedRestaurants = ref.watch(_selectedRestaurantsProvider);

                          return restaurantsAsync.when(
                              data: (availableItems) {
                                if (availableItems.isEmpty) {
                                  return const Text('لا توجد مطاعم متاحة حالياً.');
                                }

                                // إنشاء مفتاح يعتمد على كل من المطاعم المتاحة والمختارة.
                                // نستخدم IDs لضمان المقارنة الصحيحة.
                                final availableIdsString = availableItems.map((r) => r.id).join(',');
                                final selectedIdsString = selectedRestaurants.map((r) => r.id).join(',');
                                // المفتاح الآن يعكس حالة كل من القائمة المتاحة والقائمة المختارة
                                final dropdownKey = ValueKey('available:$availableIdsString;selected:$selectedIdsString');

                                // حساب المؤشرات الأولية بناءً على المطاعم المختارة
                                final initialSelectedIndexes = availableItems
                                    .asMap()
                                    .entries
                                    .where((entry) => selectedRestaurants.any((selectedRest) => selectedRest.id == entry.value.id))
                                    .map((entry) => entry.key)
                                    .toList(); // تحويل إلى قائمة

                                return DropdownField<Restaurant>(
                                  key: dropdownKey,

                                  isDense: true,
                                  refreshDropdownMenuItemsOnChange: true,
                                  // قد يكون هذا مفيداً أيضاً
                                  items: availableItems,
                                  // القائمة الكاملة المتاحة
                                  initialSelected: initialSelectedIndexes,
                                  // المؤشرات المختارة
                                  multiselect: true,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'المطاعم المصرح بها', // تعديل النص
                                    prefixIcon: Icon(Icons.restaurant_menu_outlined),
                                  ),
                                  onChanged: (selectedIndexes) {
                                    // الحصول على كائنات المطاعم المختارة من القائمة المتاحة
                                    final newlySelected = selectedIndexes.map((i) => availableItems[i]).toList();
                                    // تحديث حالة provider المطاعم المختارة
                                    ref.read(_selectedRestaurantsProvider.notifier).state = newlySelected;
                                  },
                                  // بناء النص الذي يظهر عند إغلاق الـ Dropdown
                                  childBuilder: (context, allSelectedItems, selectedIndexes) {
                                    if (selectedIndexes.isEmpty) {
                                      return const Text('اختر مطعمًا واحدًا أو أكثر');
                                    }
                                    if (selectedIndexes.length == 1) {
                                      // تأكد من أن المؤشر لا يزال صالحاً
                                      final index = selectedIndexes.single;
                                      if (index < allSelectedItems.length) {
                                        return Text(allSelectedItems.elementAt(index).name);
                                      } else {
                                        return const Text('تم اختيار مطعم'); // نص احتياطي
                                      }
                                    }
                                    return Text('${selectedIndexes.length} مطاعم تم اختيارها');
                                  },
                                  // بناء العناصر داخل القائمة المنسدلة
                                  itemBuilder: (context, restaurant, index, isSelected) {
                                    return ListTile(
                                      selected: isSelected,
                                      title: Text(restaurant.name),
                                      // يمكنك إضافة leading/trailing إذا أردت
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, stackTrace) {
                                // طباعة الخطأ للمساعدة في التصحيح
                                // print('Error loading restaurants: $e\n$stackTrace');
                                return Text('فشل تحميل قائمة المطاعم: $e');
                              });
                        },
                      ),
                    ), // نهاية Padding للـ DropdownField

                    // --- مفتاح المدير (Admin Switch) ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0, top: 0), // تقليل المسافة العلوية
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
                          const Text('منح صلاحيات المدير'), // تعديل النص
                          const SizedBox(width: 8),
                          const Tooltip(
                            message: 'المدير يمكنه إدارة المستخدمين والمطاعم الأخرى.',
                            child: Icon(Icons.info_outline, size: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    // --- زر الإرسال ---
                    Consumer(
                      builder: (context, ref, _) {
                        final isLoading = ref.watch(_isLoading);
                        // يمكن تبسيط التحقق من الصلاحية هنا إذا لم تكن هناك حاجة لعرض "!!!"
                        // final isValid = _validateFormInputs(ref);
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            // يمكنك إضافة لون للخلفية أو النص
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green,
                          ),
                          // تعطيل الزر أثناء التحميل
                          onPressed: isLoading ? null : () => _submitForm(context, ref),
                          child: isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(
                                  isEdit ? 'حفظ التعديلات' : 'إنشاء المستخدم',
                                  style: const TextStyle(fontSize: 16),
                                ),
                        );
                      },
                    ),

                    // --- عرض رسالة الخطأ ---
                    Consumer(
                      builder: (context, ref, _) {
                        final errorMessage = ref.watch(_errorMessage);
                        if (errorMessage == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 16.0), // زيادة المسافة العلوية قليلاً
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

                    // --- زر التبديل بين تسجيل الدخول والتسجيل (إذا كانت الصفحة تستخدم لهذا الغرض) ---
                    const SizedBox(height: 24),
                    if (!isEdit)
                      Consumer(
                        builder: (context, ref, _) {
                          return TextButton(
                            onPressed: ref.watch(_isLoading) ? null : () => _toggleFormType(ref),
                            child: Text(
                              ref.watch(_isLogin) ? 'ليس لديك حساب؟ تسجيل جديد' : 'لديك حساب بالفعل؟ تسجيل الدخول',
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
