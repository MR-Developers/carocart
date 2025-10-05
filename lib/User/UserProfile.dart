import 'package:carocart/Apis/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String name = '';
  String email = '';
  String? profileImageUrl; // store fetched profile image
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null) return;

    final profile = await UserService.getProfile(); // fetch from API
    if (profile != null) {
      setState(() {
        name = "${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}"
            .trim();
        email = profile['email'] ?? '';
        profileImageUrl = profile['profileImageUrl'];
        loading = false;
      });
    } else {
      setState(() => loading = false);
      // optionally show error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load profile")));
    }
  }

  void _onEditProfile() {
    Navigator.pushNamed(context, "/usereditprofile").then((_) {
      // refresh profile after coming back from edit page
      _fetchUserProfile();
    });
  }

  void _onAddresses() {
    Navigator.pushNamed(context, "/useryouraddresses");
  }

  void _onContactSupport() {
    Navigator.pushNamed(context, "/usercontactus");
  }

  void _onChangePassword() {
    Navigator.pushNamed(context, "/userchangepassword");
  }

  void _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Color(0xFF273E06);

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF273E06), Color(0xFF3E6C1F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        profileImageUrl != null && profileImageUrl!.isNotEmpty
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: profileImageUrl == null || profileImageUrl!.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0] : '?',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : "Your Name",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Options List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOptionCard(
                    icon: Icons.person,
                    title: "Edit Profile",
                    subtitle: "Update name, photo & bio",
                    onTap: _onEditProfile,
                  ),
                  _buildOptionCard(
                    icon: Icons.location_on,
                    title: "Your Addresses",
                    subtitle: "Manage delivery locations",
                    onTap: _onAddresses,
                  ),
                  _buildOptionCard(
                    icon: Icons.support_agent,
                    title: "Contact Support",
                    subtitle: "Get help & feedback",
                    onTap: _onContactSupport,
                  ),
                  _buildOptionCard(
                    icon: Icons.lock,
                    title: "Change Password",
                    subtitle: "Update your password",
                    onTap: _onChangePassword,
                  ),
                  _buildOptionCard(
                    icon: Icons.logout,
                    title: "Logout",
                    subtitle: "Sign out of your account",
                    onTap: _onLogout,
                    isDestructive: true,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : Colors.green.shade900,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
