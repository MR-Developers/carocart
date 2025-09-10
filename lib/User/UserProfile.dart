import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  // Dummy Data (replace with real)
  String name = 'Budda Manikanta Saaketh';
  String email = 'buddamanikantasaaketh@gmail.com';

  void _onEditProfile() {
    Navigator.pushNamed(context, "/usereditprofile");
  }

  void _onAddresses() {}
  void _onContactSupport() {}
  void _onChangePassword() {}
  void _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }

  String _formatLastLogin(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.green.shade600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, Colors.green.shade400],
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
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
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
            color: isDestructive ? Colors.red : Colors.green.shade700,
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

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
