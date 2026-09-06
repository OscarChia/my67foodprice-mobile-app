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
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  static const Color primaryGreen = Color(0xFF176B52);
  static const Color darkGreen = Color(0xFF0F513D);
  static const Color backgroundColor = Color(0xFFF6F8F5);
  static const Color lightGreen = Color(0xFFEAF4EF);
  static const Color textColor = Color(0xFF1F2924);

  final DatabaseService databaseService = DatabaseService();
  final ImagePicker picker = ImagePicker();

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

  final editNameController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final editFormKey = GlobalKey<FormState>();
  final passwordFormKey = GlobalKey<FormState>();

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
      final user = databaseService.getCurrentUser();

      if (user == null) {
        setState(() {
          isLoading = false;
        });

        return;
      }

      email = user.email ?? '';

      final profileData = await databaseService.getProfile();

      if (profileData != null) {
        userName = profileData['name']?.toString() ?? '';
        gender = profileData['gender']?.toString() ?? '';
        dateOfBirth = profileData['date_of_birth']?.toString() ?? '';
        priceAlerts = profileData['price_alerts'] == true;

        alertThreshold = double.tryParse(
          profileData['alert_threshold'].toString(),
        ) ?? 5;

        savedItemAlert = profileData['saved_item_alert'] == true;
      } else {
        final metadata = user.userMetadata;
        userName = metadata?['name']?.toString() ?? '';
        gender = metadata?['gender']?.toString() ?? '';
        dateOfBirth = metadata?['date_of_birth']?.toString() ?? '';
      }

      editNameController.text = userName;

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
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() {
      _image = File(
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
      final user = databaseService.getCurrentUser();

      if (user == null) {
        return;
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final newImagePath = '${appDocDir.path}/profile_${user.id}.png';

      await _image!.copy(
        newImagePath,
      );

      setState(() {
        _image = File(
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
    final user = databaseService.getCurrentUser();

    if (user == null) {
      return;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final imagePath = '${appDocDir.path}/profile_${user.id}.png';

    final file = File(
      imagePath,
    );

    if (await file.exists()) {
      setState(() {
        _image = file;
      });
    }
  }

  Future<void> updateProfile() async {
    if (!editFormKey.currentState!.validate()) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final name = editNameController.text.trim();

    try {
      await databaseService.updateProfile(
        name: name,
      );
      setState(() {
        userName = name;
        showEditProfile = false;
      });
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
          ),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update profile.',
          ),
        ),
      );
    }
  }

  Future<void> updatePassword() async {
    if (!passwordFormKey.currentState!
        .validate()) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);

    try {
      await databaseService.updatePassword(
        newPasswordController.text,
      );
      newPasswordController.clear();
      confirmPasswordController.clear();

      setState(() {
        showChangePassword = false;
      });
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Password updated successfully.',
          ),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update password.',
          ),
        ),
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
      await databaseService.updateSavedItemAlert(
        value,
      );

      setState(() {
        savedItemAlert = value;
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
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await databaseService.updateAlertThreshold(
        value,
      );
      setState(() {
        alertThreshold = value;
      });
      navigator.pop();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Alert threshold changed to ${value.toStringAsFixed(0)}%.',
          ),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update alert threshold.',
          ),
        ),
      );
    }
  }

  String getThresholdDescription(
      double value,
      ) {
    if (value == 3) {
      return 'High sensitivity';
    }

    if (value == 5) {
      return 'Recommended';
    }

    if (value == 10) {
      return 'Moderate changes';
    }

    return 'Large price changes only';
  }

  void showThresholdDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              22,
            ),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            0,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            20,
            16,
            20,
            10,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            16,
          ),
          title: const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: lightGreen,
                child: Icon(
                  Icons.percent,
                  color: primaryGreen,
                  size: 21,
                ),
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  'Alert Threshold',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose how much the price must change before an alert is triggered.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(
                height: 17,
              ),
              thresholdOption(
                3,
              ),
              const SizedBox(
                height: 9,
              ),
              thresholdOption(
                5,
              ),
              const SizedBox(
                height: 9,
              ),
              thresholdOption(
                10,
              ),
              const SizedBox(
                height: 9,
              ),
              thresholdOption(
                15,
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
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget thresholdOption(
      double value,
      ) {
    final isSelected = alertThreshold == value;

    return InkWell(
      onTap: () {
        updateAlertThreshold(
          value,
        );
      },
      borderRadius: BorderRadius.circular(
        14,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? lightGreen
              : backgroundColor,
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: isSelected
                ? primaryGreen
                : const Color(
              0xFFE3E9E6,
            ),
            width: isSelected
                ? 1.4
                : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryGreen
                    : Colors.white,
                borderRadius:
                BorderRadius.circular(
                  11,
                ),
              ),
              child: Text(
                '${value.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : primaryGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Text(
                getThresholdDescription(
                  value,
                ),
                style: const TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: primaryGreen,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> logout() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              20,
            ),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
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
      await databaseService.logoutUser();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
            (route) => false,
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to logout.',
          ),
        ),
      );
    }
  }

  void showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void showPrivacySecurity() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              20,
            ),
          ),
          title: const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: lightGreen,
                child: Icon(
                  Icons.security_outlined,
                  color: primaryGreen,
                  size: 21,
                ),
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  'Privacy & Security',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Your account only stores information required for your My67Food Price profile, including your name, gender and date of birth.\n\n'
                'Your email and password are managed securely through Supabase Authentication. Your password is not displayed inside the application.\n\n'
                'Your saved food items and notification preferences are linked to your account.',
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showHelpSupport() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              20,
            ),
          ),
          title: const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: lightGreen,
                child: Icon(
                  Icons.help_outline,
                  color: primaryGreen,
                  size: 22,
                ),
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Need help using My67Food Price?\n\n'
                'You can use the Search page to find food prices, the Map page to locate stores, and the Trend page to view price changes over time.\n\n'
                'If you experience any problem, please contact the My67Food Price support team.',
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showRateApp() {
    int selectedRating = 0;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
              title: const Text(
                'Rate My67Food Price',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              content: SingleChildScrollView(
                child:
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'How would you rate your experience?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                            (index) {
                          return IconButton(
                            onPressed: () {
                              setDialogState(
                                    () {
                                  selectedRating = index + 1;
                                },
                              );
                            },
                            icon:
                            Icon(
                              index < selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 34,
                            ),
                          );
                        },
                      ),
                    ),
                    if (selectedRating > 0)
                      Text(
                        '$selectedRating / 5',
                        style: const TextStyle(
                          color: primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: TextField(
                        controller: feedbackController,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          labelText: 'Feedback',
                          hintText: 'Tell us what you think...',
                          alignLabelWithHint: true,
                          labelStyle: const TextStyle(
                            fontSize: 14,
                          ),
                          hintStyle: const TextStyle(
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
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
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedRating == 0) {
                      showMessage(
                        'Please select a rating.',
                      );
                      return;
                    }
                    final navigator = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      await databaseService.submitAppRating(
                        rating: selectedRating,
                        feedback: feedbackController.text.trim(),
                      );

                      navigator.pop();
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Thank you for your feedback!',
                          ),
                        ),
                      );
                    } catch (e) {
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Unable to submit rating.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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
    Color iconColor = primaryGreen,
    Color iconBackground = lightGreen,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          14,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 23,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14, height: 1.4,
                        color: Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(
                  width: 10,
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color: const Color(
            0xFFE3E9E6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 12,
            offset: const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget sectionTitle(
      String title, {
        String? subtitle,
      }) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 2,
        bottom: 11,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(
              height: 5,
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget settingDivider() {
    return const Padding(
      padding: EdgeInsets.only(
        left: 60,
      ),
      child: Divider(
        height: 1,
        thickness: 0.8,
        color: Color(
          0xFFEEF1EF,
        ),
      ),
    );
  }

  Widget buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryGreen,
            darkGreen,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(
            28,
          ),
          bottomRight: Radius.circular(
            28,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(
                      0x22FFFFFF,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(
                        12,
                      ),
                    ),
                  ),
                  child:
                  Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
              ),
              SizedBox(
                width: 11,
              ),
              Expanded(
                child:
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      'Manage your account and preferences',
                      style: TextStyle(
                        color: Color(
                          0xFFDCEDE6,
                        ),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 17,
          ),
          Container(
            padding: const EdgeInsets.all(
              15,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(
                20,
              ),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.16,
                ),
              ),
            ),
            child:
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(
                        3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.12,
                            ),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child:
                      ClipOval(
                        child: _image == null ? Container(
                          color: lightGreen,
                          child: const Icon(
                            Icons.person,
                            color: primaryGreen,
                            size: 42,
                          ),
                        )
                            : Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: getImageFromGallery,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 29,
                            height: 29,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryGreen,
                                width: 1.5,
                              ),
                            ),
                            child:
                            const Icon(
                              Icons.photo_camera_outlined,
                              color: primaryGreen,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName.isEmpty ? 'User' : userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 7,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            color: Color(
                              0xFFDCEDE6,
                            ),
                            size: 15,
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Expanded(
                            child: Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(
                                  0xFFDCEDE6,
                                ),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                InkWell(
                  onTap: () {
                    editNameController.text = userName;

                    setState(() {
                      showEditProfile = !showEditProfile;
                    });
                  },
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child:
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          color: primaryGreen,
                          size: 16,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          showEditProfile
                              ? 'Close'
                              : 'Edit',
                          style: const TextStyle(
                            color: primaryGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
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
      width: double.infinity,
      padding: const EdgeInsets.all(
        17,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: const Color(
            0xFFDCE8E2,
          ),
        ),
      ),
      child: Form(
        key: editFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  color: primaryGreen,
                  size: 23,
                ),
                SizedBox(
                  width: 8,
                ),
                Text(
                  'Edit Name',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            TextFormField(
              controller: editNameController,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: const TextStyle(
                  fontSize: 16,
                ),
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: primaryGreen,
                ),
                filled: true,
                fillColor: backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
              ),
              validator: (value) {if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }

                return null;
              },
            ),
            const SizedBox(
              height: 15,
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      13,
                    ),
                  ),
                ),
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 19,
                ),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
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
      padding: const EdgeInsets.all(
        17,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: const Color(
            0xFFDCE8E2,
          ),
        ),
      ),
      child: Form(
        key: passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.lock_reset_rounded,
                  color: primaryGreen,
                  size: 22,
                ),
                SizedBox(
                  width: 8,
                ),
                Text(
                  'Update Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            TextFormField(
              controller:
              newPasswordController,
              obscureText:
              hideNewPassword,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration:
              InputDecoration(
                labelText: 'New Password',
                labelStyle: const TextStyle(
                  fontSize: 14,
                ),
                prefixIcon:
                const Icon(
                  Icons.lock_outline,
                  color:
                  primaryGreen,
                ),
                suffixIcon:
                IconButton(
                  onPressed: () {
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
                filled:
                true,
                fillColor:
                backgroundColor,
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    13,
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
              height: 13,
            ),
            TextFormField(
              controller:
              confirmPasswordController,
              obscureText:
              hideConfirmPassword,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration:
              InputDecoration(
                labelText:
                'Confirm Password',
                labelStyle: const TextStyle(
                  fontSize: 14,
                ),
                prefixIcon:
                const Icon(
                  Icons.lock_outline,
                  color:
                  primaryGreen,
                ),
                suffixIcon:
                IconButton(
                  onPressed: () {
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
                filled:
                true,
                fillColor:
                backgroundColor,
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    13,
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
              height: 15,
            ),
            SizedBox(
              width:
              double.infinity,
              height: 48,
              child:
              ElevatedButton.icon(
                onPressed:
                updatePassword,
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  primaryGreen,
                  foregroundColor:
                  Colors.white,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      13,
                    ),
                  ),
                ),
                icon:
                const Icon(
                  Icons.security_outlined,
                  size: 19,
                ),
                label: const Text(
                  'Update Password',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNotifications() {
    return sectionCard(
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
            icon:
            Icons.percent,
            title:
            'Alert Threshold',
            subtitle: priceAlerts
                ? 'Notify when price changes by this percentage or more'
                : 'Enable Price Alerts to use this setting',
            iconColor: priceAlerts
                ? primaryGreen
                : Colors.grey,
            iconBackground:
            priceAlerts
                ? lightGreen
                : const Color(
              0xFFF1F1F1,
            ),
            trailing: Text(
              '${alertThreshold.toStringAsFixed(0)}%',
              style: TextStyle(
                color: priceAlerts
                    ? primaryGreen
                    : Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: priceAlerts
                ? showThresholdDialog
                : null,
          ),
          settingDivider(),
          settingRow(
            icon:
            Icons.favorite_border,
            title:
            'Favorite Alerts',
            subtitle:
            'Automatically turn on alerts for new favorites',
            trailing:
            Switch(
              value:
              savedItemAlert,
              activeThumbColor:
              Colors.white,
              activeTrackColor:
              primaryGreen,
              onChanged:
              updateSavedItemAlert,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMoreSection() {
    return sectionCard(
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
              size: 24,
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
              size: 24,
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
              size: 24,
            ),
            onTap:
            showRateApp,
          ),
        ],
      ),
    );
  }

  Widget buildLogoutButton() {
    return InkWell(
      onTap:
      logout,
      borderRadius:
      BorderRadius.circular(
        16,
      ),
      child:
      Container(
        width:
        double.infinity,
        height: 54,
        decoration:
        BoxDecoration(
          color:
          const Color(
            0xFFF44336,
          ),
          borderRadius:
          BorderRadius.circular(
            16,
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
              size: 20,
            ),
            SizedBox(
              width: 9,
            ),
            Text(
              'Logout',
              style:
              TextStyle(
                color:
                Colors.white,
                fontSize: 15,
                fontWeight:
                FontWeight.bold,
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
                          height: 12,
                        ),
                        buildEditProfile(),
                      ],
                      const SizedBox(
                        height: 24,
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
                            Colors.black54,
                            size: 24,
                          ),
                          onTap: () {
                            setState(() {
                              showChangePassword =
                              !showChangePassword;
                            });
                          },
                        ),
                      ),
                      if (showChangePassword) ...[
                        const SizedBox(
                          height: 12,
                        ),
                        buildChangePassword(),
                      ],
                      const SizedBox(
                        height: 24,
                      ),
                      sectionTitle(
                        'Notifications',
                        subtitle:
                        'Choose how price alerts work',
                      ),
                      buildNotifications(),
                      const SizedBox(
                        height: 24,
                      ),
                      sectionTitle(
                        'More',
                        subtitle:
                        'Support, privacy and feedback',
                      ),
                      buildMoreSection(),
                      const SizedBox(
                        height: 24,
                      ),
                      buildLogoutButton(),
                      const SizedBox(
                        height: 18,
                      ),
                      const Center(
                        child:
                        Column(
                          children: [
                            Text(
                              'My67Food Price',
                              style:
                              TextStyle(
                                fontSize: 15,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                primaryGreen,
                              ),
                            ),
                            SizedBox(
                              height: 4,
                            ),
                            Text(
                              'Smart food price comparison',
                              style:
                              TextStyle(
                                fontSize: 13,
                                color:
                                Colors.black45,
                                fontWeight:
                                FontWeight.w400,
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