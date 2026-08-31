import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../services/database_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
  });

  @override
  State<ProfilePage> createState() =>
      ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  static const Color primaryGreen =
  Color(0xFF176B52);

  static const Color darkGreen =
  Color(0xFF0F513D);

  static const Color backgroundColor =
  Color(0xFFF6F8F5);

  static const Color lightGreen =
  Color(0xFFEAF4EF);

  static const Color textColor =
  Color(0xFF1F2924);

  final DatabaseService databaseService =
  DatabaseService();

  final ImagePicker picker =
  ImagePicker();

  File? _image;

  bool isLoading = true;
  bool showEditProfile = false;
  bool showChangePassword = false;

  bool hideNewPassword = true;
  bool hideConfirmPassword = true;

  bool priceAlerts = true;
  bool savedItemAlert = true;

  double alertThreshold = 5;

  String userName = '';
  String email = '';
  String gender = '';
  String dateOfBirth = '';

  final editNameController =
  TextEditingController();

  final newPasswordController =
  TextEditingController();

  final confirmPasswordController =
  TextEditingController();

  final editFormKey =
  GlobalKey<FormState>();

  final passwordFormKey =
  GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    loadProfile();
    loadProfileImage();
  }

  Future<void> loadProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user =
      databaseService.getCurrentUser();

      if (user == null) {
        setState(() {
          isLoading = false;
        });

        return;
      }

      email =
          user.email ?? '';

      final profileData =
      await databaseService.getProfile();

      if (profileData != null) {
        userName =
            profileData['name']
                ?.toString() ??
                '';

        gender =
            profileData['gender']
                ?.toString() ??
                '';

        dateOfBirth =
            profileData['date_of_birth']
                ?.toString() ??
                '';

        priceAlerts =
            profileData['price_alerts'] ==
                true;

        alertThreshold =
            double.tryParse(
              profileData[
              'alert_threshold']
                  .toString(),
            ) ??
                5;

        savedItemAlert =
            profileData[
            'saved_item_alert'] ==
                true;
      } else {
        final metadata =
            user.userMetadata;

        userName =
            metadata?['name']
                ?.toString() ??
                '';

        gender =
            metadata?['gender']
                ?.toString() ??
                '';

        dateOfBirth =
            metadata?['date_of_birth']
                ?.toString() ??
                '';
      }

      editNameController.text =
          userName;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage(
        'Unable to load profile.',
      );
    }
  }

  Future<void> getImageFromGallery() async {
    final pickedFile =
    await picker.pickImage(
      source:
      ImageSource.gallery,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() {
      _image =
          File(
            pickedFile.path,
          );
    });

    await savePicture();
  }

  Future<void> savePicture() async {
    if (_image == null) {
      return;
    }

    try {
      final user =
      databaseService.getCurrentUser();

      if (user == null) {
        return;
      }

      final appDocDir =
      await getApplicationDocumentsDirectory();

      final newImagePath =
          '${appDocDir.path}/profile_${user.id}.png';

      await _image!.copy(
        newImagePath,
      );

      setState(() {
        _image =
            File(
              newImagePath,
            );
      });

      showMessage(
        'Profile image saved.',
      );
    } catch (e) {
      showMessage(
        'Unable to save profile image.',
      );
    }
  }

  Future<void> loadProfileImage() async {
    final user =
    databaseService.getCurrentUser();

    if (user == null) {
      return;
    }

    final appDocDir =
    await getApplicationDocumentsDirectory();

    final imagePath =
        '${appDocDir.path}/profile_${user.id}.png';

    final file =
    File(
      imagePath,
    );

    if (await file.exists()) {
      setState(() {
        _image =
            file;
      });
    }
  }

  Future<void> updateProfile() async {
    if (!editFormKey.currentState!
        .validate()) {
      return;
    }

    final name =
    editNameController.text.trim();

    try {
      await databaseService
          .updateProfile(
        name:
        name,
      );

      setState(() {
        userName =
            name;

        showEditProfile =
        false;
      });

      showMessage(
        'Profile updated successfully.',
      );
    } catch (e) {
      showMessage(
        'Unable to update profile.',
      );
    }
  }

  Future<void> updatePassword() async {
    if (!passwordFormKey.currentState!
        .validate()) {
      return;
    }

    try {
      await databaseService
          .updatePassword(
        newPasswordController.text,
      );

      newPasswordController.clear();
      confirmPasswordController.clear();

      setState(() {
        showChangePassword =
        false;
      });

      showMessage(
        'Password updated successfully.',
      );
    } catch (e) {
      showMessage(
        'Unable to update password.',
      );
    }
  }

  Future<void> updatePriceAlerts(
      bool value,
      ) async {
    try {
      await databaseService
          .updatePriceAlerts(
        value,
      );

      setState(() {
        priceAlerts =
            value;
      });
    } catch (e) {
      showMessage(
        'Unable to update price alerts.',
      );
    }
  }

  Future<void> updateSavedItemAlert(
      bool value,
      ) async {
    try {
      await databaseService
          .updateSavedItemAlert(
        value,
      );

      setState(() {
        savedItemAlert =
            value;
      });
    } catch (e) {
      showMessage(
        'Unable to update saved item alert.',
      );
    }
  }

  Future<void> updateAlertThreshold(
      double value,
      ) async {
    try {
      await databaseService
          .updateAlertThreshold(
        value,
      );

      setState(() {
        alertThreshold =
            value;
      });

      Navigator.pop(
        context,
      );

      showMessage(
        'Alert threshold changed to ${value.toStringAsFixed(0)}%.',
      );
    } catch (e) {
      showMessage(
        'Unable to update alert threshold.',
      );
    }
  }

  void showThresholdDialog() {
    showDialog(
      context:
      context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title:
          const Text(
            'Alert Threshold',
          ),
          content:
          Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Text(
                'Choose the percentage change required to trigger a price alert. The alert will show the actual price difference in RM.',
              ),
              const SizedBox(
                height:
                15,
              ),
              thresholdOption(
                3,
              ),
              thresholdOption(
                5,
              ),
              thresholdOption(
                10,
              ),
              thresholdOption(
                15,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget thresholdOption(
      double value,
      ) {
    return ListTile(
      title:
      Text(
        '${value.toStringAsFixed(0)}%',
      ),
      trailing:
      alertThreshold == value
          ? const Icon(
        Icons.check,
        color:
        primaryGreen,
      )
          : null,
      onTap:
          () {
        updateAlertThreshold(
          value,
        );
      },
    );
  }

  Future<void> logout() async {
    final answer =
    await showDialog<bool>(
      context:
      context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title:
          const Text(
            'Logout',
          ),
          content:
          const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
              const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
              const Text(
                'Logout',
                style:
                TextStyle(
                  color:
                  Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (answer != true) {
      return;
    }

    try {
      await databaseService
          .logoutUser();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
          const LoginPage(),
        ),
            (route) =>
        false,
      );
    } catch (e) {
      showMessage(
        'Unable to logout.',
      );
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
        content:
        Text(
          message,
        ),
      ),
    );
  }

  void showPrivacySecurity() {
    showDialog(
      context:
      context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title:
          const Text(
            'Privacy & Security',
          ),
          content:
          const Text(
            'Your account only stores information required for your My67Food Price profile, including your name, gender and date of birth.\n\n'
                'Your email and password are managed securely through Supabase Authentication. Your password is not displayed inside the application.\n\n'
                'Your saved food items and notification preferences are linked to your account.',
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
              const Text(
                'OK',
              ),
            ),
          ],
        );
      },
    );
  }

  void showHelpSupport() {
    showDialog(
      context:
      context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title:
          const Text(
            'Help & Support',
          ),
          content:
          const Text(
            'Need help using My67Food Price?\n\n'
                'You can use the Search page to find food prices, the Map page to locate stores, and the Trend page to view price changes over time.\n\n'
                'If you experience any problem, please contact the My67Food Price support team.',
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
              const Text(
                'OK',
              ),
            ),
          ],
        );
      },
    );
  }

  void showRateApp() {
    int selectedRating =
    0;

    final feedbackController =
    TextEditingController();

    showDialog(
      context:
      context,
      builder:
          (dialogContext) {
        return StatefulBuilder(
          builder:
              (
              context,
              setDialogState,
              ) {
            return AlertDialog(
              title:
              const Text(
                'Rate My67Food Price',
              ),
              content:
              SingleChildScrollView(
                child:
                Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    const Text(
                      'How would you rate your experience?',
                    ),
                    const SizedBox(
                      height:
                      15,
                    ),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children:
                      List.generate(
                        5,
                            (index) {
                          return IconButton(
                            onPressed:
                                () {
                              setDialogState(
                                    () {
                                  selectedRating =
                                      index + 1;
                                },
                              );
                            },
                            icon:
                            Icon(
                              index < selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color:
                              Colors.amber,
                              size:
                              32,
                            ),
                          );
                        },
                      ),
                    ),
                    if (selectedRating > 0)
                      Text(
                        '$selectedRating / 5',
                        style:
                        const TextStyle(
                          color:
                          primaryGreen,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    const SizedBox(
                      height:
                      15,
                    ),
                    SizedBox(
                      height:
                      150,
                      width:
                      double.infinity,
                      child:
                      TextField(
                        controller:
                        feedbackController,
                        expands:
                        true,
                        minLines:
                        null,
                        maxLines:
                        null,
                        textAlignVertical:
                        TextAlignVertical.top,
                        decoration:
                        InputDecoration(
                          labelText:
                          'Feedback',
                          hintText:
                          'Tell us what you think...',
                          alignLabelWithHint:
                          true,
                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      () {
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
                  onPressed:
                      () async {
                    if (selectedRating == 0) {
                      showMessage(
                        'Please select a rating.',
                      );

                      return;
                    }

                    try {
                      await databaseService
                          .submitAppRating(
                        rating:
                        selectedRating,
                        feedback:
                        feedbackController
                            .text
                            .trim(),
                      );

                      Navigator.pop(
                        dialogContext,
                      );

                      showMessage(
                        'Thank you for your feedback!',
                      );
                    } catch (e) {
                      showMessage(
                        'Unable to submit rating.',
                      );
                    }
                  },
                  child:
                  const Text(
                    'Submit',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget settingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color iconColor =
        primaryGreen,
    Color iconBackground =
        lightGreen,
  }) {
    return Material(
      color:
      Colors.transparent,
      child:
      InkWell(
        onTap:
        onTap,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        child:
        Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal:
            4,
            vertical:
            11,
          ),
          child:
          Row(
            children: [
              Container(
                width:
                44,
                height:
                44,
                decoration:
                BoxDecoration(
                  color:
                  iconBackground,
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
                child:
                Icon(
                  icon,
                  color:
                  iconColor,
                  size:
                  21,
                ),
              ),
              const SizedBox(
                width:
                13,
              ),
              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                      const TextStyle(
                        fontSize:
                        12,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        textColor,
                      ),
                    ),
                    const SizedBox(
                      height:
                      4,
                    ),
                    Text(
                      subtitle,
                      style:
                      const TextStyle(
                        fontSize:
                        9,
                        height:
                        1.35,
                        color:
                        Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(
                  width:
                  10,
                ),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionCard({
    required Widget child,
  }) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        13,
        vertical:
        3,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border:
        Border.all(
          color:
          const Color(
            0xFFE7ECE9,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha:
              0.035,
            ),
            blurRadius:
            12,
            offset:
            const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child:
      child,
    );
  }

  Widget sectionTitle(
      String title, {
        String? subtitle,
      }) {
    return Padding(
      padding:
      const EdgeInsets.only(
        left:
        2,
        bottom:
        10,
      ),
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
            const TextStyle(
              fontSize:
              16,
              fontWeight:
              FontWeight.w800,
              color:
              textColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(
              height:
              3,
            ),
            Text(
              subtitle,
              style:
              const TextStyle(
                fontSize:
                9,
                color:
                Colors.black45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget settingDivider() {
    return const Padding(
      padding:
      EdgeInsets.only(
        left:
        57,
      ),
      child:
      Divider(
        height:
        1,
        thickness:
        0.7,
        color:
        Color(
          0xFFEEF1EF,
        ),
      ),
    );
  }

  Widget buildProfileHeader() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        28,
      ),
      decoration:
      const BoxDecoration(
        gradient:
        LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            primaryGreen,
            darkGreen,
          ],
        ),
        borderRadius:
        BorderRadius.only(
          bottomLeft:
          Radius.circular(
            30,
          ),
          bottomRight:
          Radius.circular(
            30,
          ),
        ),
      ),
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SizedBox(
                width:
                36,
                height:
                36,
                child:
                DecoratedBox(
                  decoration:
                  BoxDecoration(
                    color:
                    Color(
                      0x22FFFFFF,
                    ),
                    borderRadius:
                    BorderRadius.all(
                      Radius.circular(
                        11,
                      ),
                    ),
                  ),
                  child:
                  Icon(
                    Icons.person_outline,
                    color:
                    Colors.white,
                    size:
                    21,
                  ),
                ),
              ),
              SizedBox(
                width:
                10,
              ),
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style:
                    TextStyle(
                      color:
                      Colors.white,
                      fontSize:
                      22,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height:
                    1,
                  ),
                  Text(
                    'Manage your account and preferences',
                    style:
                    TextStyle(
                      color:
                      Color(
                        0xFFDCEDE6,
                      ),
                      fontSize:
                      9,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(
            height:
            22,
          ),
          Container(
            padding:
            const EdgeInsets.all(
              14,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.white.withValues(
                alpha:
                0.12,
              ),
              borderRadius:
              BorderRadius.circular(
                20,
              ),
              border:
              Border.all(
                color:
                Colors.white.withValues(
                  alpha:
                  0.15,
                ),
              ),
            ),
            child:
            Row(
              children: [
                Stack(
                  clipBehavior:
                  Clip.none,
                  children: [
                    Container(
                      width:
                      76,
                      height:
                      76,
                      padding:
                      const EdgeInsets.all(
                        3,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        Colors.white,
                        shape:
                        BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                            Colors.black.withValues(
                              alpha:
                              0.12,
                            ),
                            blurRadius:
                            10,
                          ),
                        ],
                      ),
                      child:
                      ClipOval(
                        child:
                        _image == null
                            ? Container(
                          color:
                          lightGreen,
                          child:
                          const Icon(
                            Icons.person,
                            color:
                            primaryGreen,
                            size:
                            39,
                          ),
                        )
                            : Image.file(
                          _image!,
                          fit:
                          BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right:
                      -2,
                      bottom:
                      -2,
                      child:
                      Material(
                        color:
                        Colors.transparent,
                        child:
                        InkWell(
                          onTap:
                          getImageFromGallery,
                          customBorder:
                          const CircleBorder(),
                          child:
                          Container(
                            width:
                            27,
                            height:
                            27,
                            decoration:
                            BoxDecoration(
                              color:
                              Colors.white,
                              shape:
                              BoxShape.circle,
                              border:
                              Border.all(
                                color:
                                primaryGreen,
                                width:
                                1.5,
                              ),
                            ),
                            child:
                            const Icon(
                              Icons.photo_camera_outlined,
                              color:
                              primaryGreen,
                              size:
                              14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  width:
                  15,
                ),
                Expanded(
                  child:
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName.isEmpty
                            ? 'User'
                            : userName,
                        maxLines:
                        1,
                        overflow:
                        TextOverflow.ellipsis,
                        style:
                        const TextStyle(
                          color:
                          Colors.white,
                          fontSize:
                          17,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height:
                        5,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            color:
                            Color(
                              0xFFDCEDE6,
                            ),
                            size:
                            12,
                          ),
                          const SizedBox(
                            width:
                            5,
                          ),
                          Expanded(
                            child:
                            Text(
                              email,
                              maxLines:
                              1,
                              overflow:
                              TextOverflow.ellipsis,
                              style:
                              const TextStyle(
                                color:
                                Color(
                                  0xFFDCEDE6,
                                ),
                                fontSize:
                                9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width:
                  8,
                ),
                InkWell(
                  onTap:
                      () {
                    editNameController.text =
                        userName;

                    setState(() {
                      showEditProfile =
                      !showEditProfile;
                    });
                  },
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                  child:
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal:
                      12,
                      vertical:
                      8,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.white,
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                    child:
                    Row(
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          color:
                          primaryGreen,
                          size:
                          14,
                        ),
                        const SizedBox(
                          width:
                          4,
                        ),
                        Text(
                          showEditProfile
                              ? 'Close'
                              : 'Edit',
                          style:
                          const TextStyle(
                            color:
                            primaryGreen,
                            fontSize:
                            9,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEditProfile() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border:
        Border.all(
          color:
          const Color(
            0xFFDCE8E2,
          ),
        ),
      ),
      child:
      Form(
        key:
        editFormKey,
        child:
        Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  color:
                  primaryGreen,
                  size:
                  21,
                ),
                SizedBox(
                  width:
                  7,
                ),
                Text(
                  'Edit Profile',
                  style:
                  TextStyle(
                    fontSize:
                    14,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height:
              15,
            ),
            TextFormField(
              controller:
              editNameController,
              decoration:
              const InputDecoration(
                labelText:
                'Full Name',
                prefixIcon:
                Icon(
                  Icons.person_outline,
                ),
              ),
              validator:
                  (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Please enter your name';
                }

                return null;
              },
            ),
            const SizedBox(
              height:
              15,
            ),
            SizedBox(
              width:
              double.infinity,
              child:
              ElevatedButton.icon(
                onPressed:
                updateProfile,
                icon:
                const Icon(
                  Icons.check_circle_outline,
                  size:
                  18,
                ),
                label:
                const Text(
                  'Save Changes',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildChangePassword() {
    return Container(
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border:
        Border.all(
          color:
          const Color(
            0xFFDCE8E2,
          ),
        ),
      ),
      child:
      Form(
        key:
        passwordFormKey,
        child:
        Column(
          children: [
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
                  onPressed:
                      () {
                    setState(() {
                      hideNewPassword =
                      !hideNewPassword;
                    });
                  },
                  icon:
                  Icon(
                    hideNewPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator:
                  (value) {
                if (value == null ||
                    value.isEmpty) {
                  return 'Please enter new password';
                }

                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }

                return null;
              },
            ),
            const SizedBox(
              height:
              12,
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
                  onPressed:
                      () {
                    setState(() {
                      hideConfirmPassword =
                      !hideConfirmPassword;
                    });
                  },
                  icon:
                  Icon(
                    hideConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator:
                  (value) {
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
              height:
              15,
            ),
            SizedBox(
              width:
              double.infinity,
              child:
              ElevatedButton.icon(
                onPressed:
                updatePassword,
                icon:
                const Icon(
                  Icons.security_outlined,
                  size:
                  18,
                ),
                label:
                const Text(
                  'Update Password',
                ),
              ),
            ),
          ],
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
      body:
      SafeArea(
        child:
        isLoading
            ? const Center(
          child:
          CircularProgressIndicator(
            color:
            primaryGreen,
          ),
        )
            : RefreshIndicator(
          color:
          primaryGreen,
          onRefresh:
          loadProfile,
          child:
          SingleChildScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            child:
            Column(
              children: [
                buildProfileHeader(),
                Padding(
                  padding:
                  const EdgeInsets.fromLTRB(
                    16,
                    20,
                    16,
                    30,
                  ),
                  child:
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      sectionTitle(
                        'Account Information',
                        subtitle:
                        'Your personal account details',
                      ),
                      sectionCard(
                        child:
                        Column(
                          children: [
                            settingRow(
                              icon:
                              Icons.person_outline,
                              title:
                              'Name',
                              subtitle:
                              userName.isEmpty
                                  ? 'Not provided'
                                  : userName,
                            ),
                            settingDivider(),
                            settingRow(
                              icon:
                              Icons.email_outlined,
                              title:
                              'Email',
                              subtitle:
                              email.isEmpty
                                  ? 'Not provided'
                                  : email,
                            ),
                            settingDivider(),
                            settingRow(
                              icon:
                              Icons.wc_outlined,
                              title:
                              'Gender',
                              subtitle:
                              gender.isEmpty
                                  ? 'Not provided'
                                  : gender,
                            ),
                            settingDivider(),
                            settingRow(
                              icon:
                              Icons.cake_outlined,
                              title:
                              'Date of Birth',
                              subtitle:
                              dateOfBirth.isEmpty
                                  ? 'Not provided'
                                  : dateOfBirth,
                            ),
                          ],
                        ),
                      ),
                      if (showEditProfile) ...[
                        const SizedBox(
                          height:
                          12,
                        ),
                        buildEditProfile(),
                      ],
                      const SizedBox(
                        height:
                        24,
                      ),
                      sectionTitle(
                        'Security',
                        subtitle:
                        'Keep your account protected',
                      ),
                      sectionCard(
                        child:
                        settingRow(
                          icon:
                          Icons.lock_outline,
                          title:
                          'Change Password',
                          subtitle:
                          'Update your account password',
                          trailing:
                          Icon(
                            showChangePassword
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color:
                            Colors.black45,
                          ),
                          onTap:
                              () {
                            setState(() {
                              showChangePassword =
                              !showChangePassword;
                            });
                          },
                        ),
                      ),
                      if (showChangePassword) ...[
                        const SizedBox(
                          height:
                          12,
                        ),
                        buildChangePassword(),
                      ],
                      const SizedBox(
                        height:
                        24,
                      ),
                      sectionTitle(
                        'Notifications',
                        subtitle:
                        'Choose how price alerts work',
                      ),
                      sectionCard(
                        child:
                        Column(
                          children: [
                            settingRow(
                              icon:
                              Icons.notifications_active_outlined,
                              title:
                              'Price Alerts',
                              subtitle:
                              'Notify when saved food prices change',
                              trailing:
                              Switch(
                                value:
                                priceAlerts,
                                activeThumbColor:
                                Colors.white,
                                activeTrackColor:
                                primaryGreen,
                                onChanged:
                                updatePriceAlerts,
                              ),
                            ),
                            settingDivider(),
                            settingRow(
                              icon: Icons.percent,
                              title: 'Alert Threshold',
                              subtitle:
                              'Notify when price changes by this percentage or more',
                              trailing: Text(
                                '${alertThreshold.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: showThresholdDialog,
                            ),
                            settingDivider(),
                            settingRow(
                              icon: Icons.favorite_border,
                              title: 'Favorite Alerts',
                              subtitle:
                              'Automatically turn on alerts for new favorites',
                              trailing: Switch(
                                value: savedItemAlert,
                                activeThumbColor: Colors.white,
                                activeTrackColor: primaryGreen,
                                onChanged: updateSavedItemAlert,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height:
                        24,
                      ),
                      sectionTitle(
                        'More',
                        subtitle:
                        'Support, privacy and feedback',
                      ),
                      sectionCard(
                        child:
                        Column(
                          children: [
                            settingRow(
                              icon:
                              Icons.security_outlined,
                              title:
                              'Privacy & Security',
                              subtitle:
                              'Learn how your account information is protected',
                              trailing:
                              const Icon(
                                Icons.chevron_right,
                                color:
                                Colors.black38,
                              ),
                              onTap:
                              showPrivacySecurity,
                            ),
                            settingDivider(),
                            settingRow(
                              icon:
                              Icons.help_outline,
                              title:
                              'Help & Support',
                              subtitle:
                              'Get help using My67Food Price',
                              trailing:
                              const Icon(
                                Icons.chevron_right,
                                color:
                                Colors.black38,
                              ),
                              onTap:
                              showHelpSupport,
                            ),
                            settingDivider(),
                            settingRow(
                              icon:
                              Icons.star_outline,
                              title:
                              'Rate My67Food Price',
                              subtitle:
                              'Share your experience and feedback',
                              trailing:
                              const Icon(
                                Icons.chevron_right,
                                color:
                                Colors.black38,
                              ),
                              onTap:
                              showRateApp,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height:
                        24,
                      ),
                      InkWell(
                        onTap:
                        logout,
                        borderRadius:
                        BorderRadius.circular(
                          17,
                        ),
                        child:
                        Container(
                          width:
                          double.infinity,
                          height:
                          54,
                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                              0xFFF44336,
                            ),
                            borderRadius:
                            BorderRadius.circular(
                              17,
                            ),
                          ),
                          child:
                          const Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color:
                                Colors.white,
                                size:
                                19,
                              ),
                              SizedBox(
                                width:
                                8,
                              ),
                              Text(
                                'Logout',
                                style:
                                TextStyle(
                                  color:
                                  Colors.white,
                                  fontSize:
                                  12,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height:
                        16,
                      ),
                      const Center(
                        child:
                        Column(
                          children: [
                            Text(
                              'My67Food Price',
                              style:
                              TextStyle(
                                fontSize:
                                10,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                primaryGreen,
                              ),
                            ),
                            SizedBox(
                              height:
                              3,
                            ),
                            Text(
                              'Smart food price comparison',
                              style:
                              TextStyle(
                                fontSize:
                                8,
                                color:
                                Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
    editNameController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }
}