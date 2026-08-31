import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'register_page.dart';
import '../main_navigation_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState
    extends State<LoginPage> {
  final _formKey =
  GlobalKey<FormState>();

  final DatabaseService databaseService =
  DatabaseService();

  final emailController =
  TextEditingController();

  final passwordController =
  TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  Future<void> loginUser() async {
    if (isLoading) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response =
      await databaseService.loginUser(
        email:
        emailController.text.trim(),
        password:
        passwordController.text.trim(),
      );

      final user =
          response.user;

      if (user == null) {
        showMessage(
          'Unable to login.',
        );

        return;
      }

      if (user.emailConfirmedAt ==
          null) {
        await databaseService
            .logoutUser();

        showMessage(
          'Please verify your email before logging in.',
        );

        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
          const MainNavigationPage(),
        ),
            (route) => false,
      );
    } catch (e) {
      final errorMessage =
      e.toString().toLowerCase();

      if (errorMessage.contains(
        'email not confirmed',
      )) {
        showMessage(
          'Please verify your email before logging in.',
        );
      } else if (errorMessage.contains(
        'invalid login credentials',
      )) {
        showMessage(
          'Incorrect email or password.',
        );
      } else {
        showMessage(
          'Unable to login. Please try again.',
        );
      }
    } finally {
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
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  Future<void>
  showForgotPasswordDialog() async {
    final resetEmailController =
    TextEditingController(
      text:
      emailController.text.trim(),
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Forgot Password',
          ),
          content: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Text(
                'Enter your email address. '
                    'A password reset link will be sent to your email.',
              ),
              const SizedBox(
                height: 15,
              ),
              TextField(
                controller:
                resetEmailController,
                keyboardType:
                TextInputType
                    .emailAddress,
                decoration:
                const InputDecoration(
                  labelText:
                  'Email',
                  prefixIcon:
                  Icon(
                    Icons.email_outlined,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
              const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () async {
                final email =
                resetEmailController
                    .text
                    .trim();

                if (email.isEmpty ||
                    !email.contains(
                      '@',
                    )) {
                  showMessage(
                    'Please enter a valid email.',
                  );

                  return;
                }

                try {
                  await databaseService
                      .resetPassword(
                    email,
                  );

                  Navigator.pop(
                    dialogContext,
                  );

                  showMessage(
                    'Password reset email sent. Please check your email.',
                  );
                } catch (e) {
                  showMessage(
                    'Unable to send password reset email.',
                  );
                }
              },
              child:
              const Text(
                'Send Reset Link',
              ),
            ),
          ],
        );
      },
    );

    resetEmailController.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      body: Container(
        width:
        double.infinity,
        height:
        double.infinity,
        decoration:
        const BoxDecoration(
          gradient:
          LinearGradient(
            begin:
            Alignment.topCenter,
            end:
            Alignment.bottomCenter,
            colors: [
              Color(
                0xFF176B52,
              ),
              Color(
                0xFF0F513D,
              ),
              Color(
                0xFFF6F8F5,
              ),
              Color(
                0xFFF6F8F5,
              ),
            ],
            stops: [
              0.0,
              0.35,
              0.35,
              1.0,
            ],
          ),
        ),
        child: SafeArea(
          child:
          SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Column(
              children: [
                const SizedBox(
                  height: 35,
                ),

                Container(
                  width: 82,
                  height: 82,
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                      24,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                        Colors.black
                            .withValues(
                          alpha: 0.12,
                        ),
                        blurRadius:
                        18,
                        offset:
                        const Offset(
                          0,
                          8,
                        ),
                      ),
                    ],
                  ),
                  child:
                  const Icon(
                    Icons
                        .shopping_basket_rounded,
                    size: 45,
                    color:
                    Color(
                      0xFF176B52,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                const Text(
                  'My67Food Price',
                  style:
                  TextStyle(
                    color:
                    Colors.white,
                    fontSize:
                    27,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                const Text(
                  'Compare smarter. Save better.',
                  style:
                  TextStyle(
                    color:
                    Color(
                      0xFFE0F2EA,
                    ),
                    fontSize:
                    14,
                  ),
                ),

                const SizedBox(
                  height: 35,
                ),

                Container(
                  width:
                  double.infinity,
                  padding:
                  const EdgeInsets.all(
                    24,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                      26,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                        Colors.black
                            .withValues(
                          alpha: 0.08,
                        ),
                        blurRadius:
                        24,
                        offset:
                        const Offset(
                          0,
                          10,
                        ),
                      ),
                    ],
                  ),
                  child: Form(
                    key:
                    _formKey,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        const Text(
                          'Welcome Back',
                          style:
                          TextStyle(
                            fontSize:
                            24,
                            fontWeight:
                            FontWeight.bold,
                            color:
                            Color(
                              0xFF1F2924,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        const Text(
                          'Login to check and compare food prices.',
                          style:
                          TextStyle(
                            fontSize:
                            13,
                            color:
                            Colors.black54,
                          ),
                        ),

                        const SizedBox(
                          height: 26,
                        ),

                        const Text(
                          'Email Address',
                          style:
                          TextStyle(
                            fontSize:
                            13,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        TextFormField(
                          controller:
                          emailController,
                          keyboardType:
                          TextInputType
                              .emailAddress,
                          decoration:
                          const InputDecoration(
                            hintText:
                            'Enter your email',
                            prefixIcon:
                            Icon(
                              Icons
                                  .email_outlined,
                            ),
                          ),
                          validator:
                              (value) {
                            if (value ==
                                null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Please enter your email';
                            }

                            if (!value
                                .contains(
                              '@',
                            )) {
                              return 'Please enter a valid email';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        const Text(
                          'Password',
                          style:
                          TextStyle(
                            fontSize:
                            13,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        TextFormField(
                          controller:
                          passwordController,
                          obscureText:
                          hidePassword,
                          decoration:
                          InputDecoration(
                            hintText:
                            'Enter your password',
                            prefixIcon:
                            const Icon(
                              Icons
                                  .lock_outline,
                            ),
                            suffixIcon:
                            IconButton(
                              onPressed:
                                  () {
                                setState(
                                        () {
                                      hidePassword =
                                      !hidePassword;
                                    });
                              },
                              icon:
                              Icon(
                                hidePassword
                                    ? Icons
                                    .visibility_off_outlined
                                    : Icons
                                    .visibility_outlined,
                              ),
                            ),
                          ),
                          validator:
                              (value) {
                            if (value ==
                                null ||
                                value
                                    .isEmpty) {
                              return 'Please enter your password';
                            }

                            if (value
                                .length <
                                6) {
                              return 'Password must be at least 6 characters';
                            }

                            return null;
                          },
                        ),

                        Align(
                          alignment:
                          Alignment
                              .centerRight,
                          child:
                          TextButton(
                            onPressed:
                            showForgotPasswordDialog,
                            child:
                            const Text(
                              'Forgot Password?',
                              style:
                              TextStyle(
                                color:
                                Color(
                                  0xFF176B52,
                                ),
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        SizedBox(
                          width:
                          double.infinity,
                          child:
                          ElevatedButton(
                            onPressed:
                            isLoading
                                ? null
                                : () {
                              if (_formKey
                                  .currentState!
                                  .validate()) {
                                loginUser();
                              }
                            },
                            child:
                            isLoading
                                ? const SizedBox(
                              width:
                              23,
                              height:
                              23,
                              child:
                              CircularProgressIndicator(
                                strokeWidth:
                                2.5,
                                color:
                                Colors.white,
                              ),
                            )
                                : const Text(
                              'Login',
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        Row(
                          children: [
                            const Expanded(
                              child:
                              Divider(),
                            ),
                            Padding(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal:
                                12,
                              ),
                              child:
                              Text(
                                'New to My67Food?',
                                style:
                                TextStyle(
                                  fontSize:
                                  12,
                                  color:
                                  Colors
                                      .grey
                                      .shade600,
                                ),
                              ),
                            ),
                            const Expanded(
                              child:
                              Divider(),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        SizedBox(
                          width:
                          double.infinity,
                          height: 52,
                          child:
                          OutlinedButton(
                            style:
                            OutlinedButton
                                .styleFrom(
                              foregroundColor:
                              const Color(
                                0xFF176B52,
                              ),
                              side:
                              const BorderSide(
                                color:
                                Color(
                                  0xFF176B52,
                                ),
                              ),
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                  14,
                                ),
                              ),
                            ),
                            onPressed:
                            isLoading
                                ? null
                                : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                  const RegisterPage(),
                                ),
                              );
                            },
                            child:
                            const Text(
                              'Create New Account',
                              style:
                              TextStyle(
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                const Text(
                  'Malaysia Food Price Comparison',
                  style:
                  TextStyle(
                    fontSize:
                    11,
                    color:
                    Colors.black45,
                  ),
                ),

                const SizedBox(
                  height: 20,
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
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }
}