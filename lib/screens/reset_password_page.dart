import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
  });

  @override
  State<ResetPasswordPage> createState() =>
      _ResetPasswordPageState();
}

class _ResetPasswordPageState
    extends State<ResetPasswordPage> {
  final formKey =
  GlobalKey<FormState>();

  final newPasswordController =
  TextEditingController();

  final confirmPasswordController =
  TextEditingController();

  bool hideNewPassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  Future<void> updatePassword() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await Supabase.instance.client.auth
          .updateUser(
        UserAttributes(
          password:
          newPasswordController.text.trim(),
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password updated successfully.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      await Supabase.instance.client.auth.signOut();

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
          const LoginPage(),
        ),
            (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message,
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update password: $e',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reset Password',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(
            20,
          ),
          child: Form(
            key:
            formKey,
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 20,
                ),

                const Center(
                  child: Icon(
                    Icons.lock_reset,
                    size: 80,
                    color:
                    Color(0xFF176B52),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                const Center(
                  child: Text(
                    'Create New Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Center(
                  child: Text(
                    'Enter your new password below.',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      color:
                      Colors.black54,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),

                TextFormField(
                  controller:
                  newPasswordController,
                  obscureText:
                  hideNewPassword,
                  decoration:
                  InputDecoration(
                    labelText:
                    'New Password',
                    prefixIcon:
                    const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon:
                    IconButton(
                      onPressed: () {
                        setState(() {
                          hideNewPassword =
                          !hideNewPassword;
                        });
                      },
                      icon: Icon(
                        hideNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Please enter your new password';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 20,
                ),

                TextFormField(
                  controller:
                  confirmPasswordController,
                  obscureText:
                  hideConfirmPassword,
                  decoration:
                  InputDecoration(
                    labelText:
                    'Confirm Password',
                    prefixIcon:
                    const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon:
                    IconButton(
                      onPressed: () {
                        setState(() {
                          hideConfirmPassword =
                          !hideConfirmPassword;
                        });
                      },
                      icon: Icon(
                        hideConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Please confirm your password';
                    }

                    if (value !=
                        newPasswordController.text) {
                      return 'Passwords do not match';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 25,
                ),

                SizedBox(
                  width:
                  double.infinity,
                  child:
                  ElevatedButton(
                    onPressed:
                    isLoading
                        ? null
                        : updatePassword,
                    child:
                    isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color:
                        Colors.white,
                      ),
                    )
                        : const Text(
                      'Update Password',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}