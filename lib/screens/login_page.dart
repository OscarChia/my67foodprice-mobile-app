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
  static const Color primaryGreen =
  Color(0xFF176B52);

  static const Color darkGreen =
  Color(0xFF0F513D);

  static const Color backgroundColor =
  Color(0xFFF6F8F5);

  static const Color textColor =
  Color(0xFF1F2924);

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
        email: emailController.text.trim(),
        password:
        passwordController.text.trim(),
      );

      final user = response.user;

      if (user == null) {
        setState(() {
          isLoading = false;
        });

        showMessage(
          'Unable to login.',
        );

        return;
      }

      if (user.emailConfirmedAt == null) {
        await databaseService.logoutUser();

        setState(() {
          isLoading = false;
        });

        showMessage(
          'Please verify your email before logging in.',
        );

        return;
      }

      setState(() {
        isLoading = false;
      });

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

      setState(() {
        isLoading = false;
      });

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

  InputDecoration fieldDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: Colors.black45,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        icon,
        color: primaryGreen,
        size: 22,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: backgroundColor,
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide: BorderSide.none,
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: Color(
            0xFFE1E8E4,
          ),
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: primaryGreen,
          width: 1.5,
        ),
      ),
      errorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      backgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration:
        const BoxDecoration(
          gradient: LinearGradient(
            begin:
            Alignment.topCenter,
            end:
            Alignment.bottomCenter,
            colors: [
              primaryGreen,
              darkGreen,
              backgroundColor,
              backgroundColor,
            ],
            stops: [
              0.0,
              0.36,
              0.36,
              1.0,
            ],
          ),
        ),
        child: SafeArea(
          child:
          SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Column(
              children: [
                const SizedBox(
                  height: 30,
                ),

                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset(
                    'assets/images/my67food_price_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                const Text(
                  'My67Food Price',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                const Text(
                  'Compare smarter. Save better.',
                  style: TextStyle(
                    color: Color(
                      0xFFE0F2EA,
                    ),
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 34,
                ),

                Container(
                  width:
                  double.infinity,
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    22,
                    24,
                    22,
                    24,
                  ),
                  decoration:
                  BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius
                        .circular(
                      25,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors
                            .black
                            .withValues(
                          alpha: 0.07,
                        ),
                        blurRadius: 24,
                        offset:
                        const Offset(
                          0,
                          10,
                        ),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        const Text(
                          'Welcome Back',
                          style:
                          TextStyle(
                            fontSize: 25,
                            fontWeight:
                            FontWeight
                                .w800,
                            color:
                            textColor,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        const Text(
                          'Login to check and compare food prices.',
                          style:
                          TextStyle(
                            fontSize: 14,
                            color: Colors
                                .black54,
                            fontWeight:
                            FontWeight
                                .w500,
                          ),
                        ),

                        const SizedBox(
                          height: 25,
                        ),

                        const Text(
                          'Email Address',
                          style:
                          TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight
                                .w700,
                            color:
                            textColor,
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
                          textInputAction:
                          TextInputAction
                              .next,
                          style:
                          const TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight
                                .w500,
                            color:
                            textColor,
                          ),
                          decoration:
                          fieldDecoration(
                            hintText:
                            'Enter your email',
                            icon: Icons
                                .email_outlined,
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
                          height: 20,
                        ),

                        const Text(
                          'Password',
                          style:
                          TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight
                                .w700,
                            color:
                            textColor,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        TextFormField(
                          controller: passwordController,
                          obscureText: hidePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (value) {
                            if (isLoading) {
                              return;
                            }

                            if (_formKey.currentState!.validate()) {
                              loginUser();
                            }
                          },
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                          decoration: fieldDecoration(
                            hintText: 'Enter your password',
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  hidePassword = !hidePassword;
                                });
                              },
                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.black54,
                                size: 21,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
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

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  14,
                                ),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () {
                              if (_formKey.currentState!.validate()) {
                                loginUser();
                              }
                            },
                            child: isLoading
                                ? const SizedBox(
                              width: 23,
                              height: 23,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
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
                                  13,
                                  color: Colors
                                      .grey
                                      .shade600,
                                  fontWeight:
                                  FontWeight
                                      .w500,
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
                          height: 17,
                        ),

                        SizedBox(
                          width: double
                              .infinity,
                          height: 54,
                          child:
                          OutlinedButton(
                            style:
                            OutlinedButton
                                .styleFrom(
                              foregroundColor:
                              primaryGreen,
                              side:
                              const BorderSide(
                                color:
                                primaryGreen,
                                width: 1.2,
                              ),
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  14,
                                ),
                              ),
                            ),
                            onPressed:
                            isLoading
                                ? null
                                : () {
                              Navigator
                                  .push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                  const RegisterPage(),
                                ),
                              );
                            },
                            child:
                            const Text(
                              'Create New Account',
                              style:
                              TextStyle(
                                fontSize: 15,
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                const Text(
                  'Malaysia Food Price Comparison',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 25,
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