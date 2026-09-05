import 'package:flutter/material.dart';
import '../services/database_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService databaseService = DatabaseService();
  final nameController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? selectedGender;

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  Future<void> selectDateOfBirth() async {
    final selectedDate =
    await showDatePicker(
      context: context,
      initialDate: DateTime(
        2000,
        1,
        1,
      ),
      firstDate: DateTime(
        1900,
        1,
        1,
      ),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      final year =
      selectedDate.year
          .toString();

      final month =
      selectedDate.month
          .toString()
          .padLeft(
        2,
        '0',
      );

      final day =
      selectedDate.day
          .toString()
          .padLeft(
        2,
        '0',
      );

      setState(() {
        dateOfBirthController.text =
        '$year-$month-$day';
      });
    }
  }

  Future<void> registerUser() async {
    if (isLoading) {
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = nameController.text.trim();
    final gender = selectedGender!;
    final dateOfBirth = dateOfBirthController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    final verifyDialogRoute = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Verify Your Email',
          ),
          content: Text(
            'A verification email has been sent to\n\n'
                '$email\n\n'
                'Please check your email and verify your account before logging in.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                navigator.pop();
              },
              child: const Text(
                'Go to Login',
              ),
            ),
          ],
        );
      },
    );

    setState(() {
      isLoading = true;
    });

    try {
      final response = await databaseService.registerUser(
        name: name,
        gender: gender,
        dateOfBirth: dateOfBirth,
        email: email,
        password: password,
      );

      if (response.user == null) {
        messenger.hideCurrentSnackBar();

        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to create account.',
            ),
          ),
        );

        setState(() {
          isLoading = false;
        });

        return;
      }

      await navigator.push(
        verifyDialogRoute,
      );

      navigator.pop();
    } catch (e) {
      messenger.hideCurrentSnackBar();

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Registration failed. Please try again.',
          ),
        ),
      );

      setState(() {
        isLoading = false;
      });
    }
  }

  void showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),

              const Icon(
                Icons.person_add,
                size: 80,
                color: Color(
                  0xFF176B52,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(
                    Icons.person,
                  ),
                ),
                validator: (value) {
                  if (
                  value == null || value.trim().isEmpty
                  ) {
                    return 'Please enter your name';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 20,
              ),

              DropdownButtonFormField<String>(
                initialValue: selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(
                    Icons.wc,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Male',
                    child: Text(
                      'Male',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Female',
                    child: Text(
                      'Female',
                    ),
                  ),
                  DropdownMenuItem(
                    value:
                    'Prefer not to say',
                    child: Text(
                      'Prefer not to say',
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedGender =
                        value;
                  });
                },
                validator: (value) {
                  if (
                  value == null ||
                      value.isEmpty
                  ) {
                    return 'Please select your gender';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 20,
              ),

              TextFormField(
                controller: dateOfBirthController,
                readOnly: true,
                onTap: selectDateOfBirth,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icon(
                    Icons.cake,
                  ),
                  suffixIcon: Icon(
                    Icons.calendar_month,
                  ),
                ),
                validator: (value) {
                  if (
                  value == null || value.trim().isEmpty
                  ) {
                    return 'Please select your date of birth';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 20,
              ),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(
                    Icons.email,
                  ),
                ),
                validator: (value) {
                  if (
                  value == null || value.trim().isEmpty
                  ) {
                    return 'Please enter your email';
                  }

                  if (
                  !value.contains(
                    '@',
                  )
                  ) {
                    return 'Please enter a valid email';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 20,
              ),

              TextFormField(
                controller: passwordController,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(
                    Icons.lock,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (
                  value == null ||
                      value.isEmpty
                  ) {
                    return 'Please enter your password';
                  }

                  if (
                  value.length < 6
                  ) {
                    return 'Password must be at least 6 characters';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 20,
              ),

              TextFormField(
                controller: confirmPasswordController,
                obscureText: hideConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hideConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        hideConfirmPassword =
                        !hideConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (
                  value == null ||
                      value.isEmpty
                  ) {
                    return 'Please confirm your password';
                  }

                  if (
                  value != passwordController.text
                  ) {
                    return 'Passwords do not match';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 25,
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                    if (
                    _formKey
                        .currentState!
                        .validate()
                    ) {
                      registerUser();
                    }
                  },
                  child: isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Register',
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                  Navigator.pop(
                    context,
                  );
                },
                child: const Text(
                  'Already have an account? Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    dateOfBirthController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }
}