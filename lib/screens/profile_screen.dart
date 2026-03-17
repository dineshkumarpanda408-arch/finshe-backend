import 'package:flutter/material.dart'; import 'package:provider/provider.dart'; import '../providers/app_provider.dart'; import '../models/user_model.dart';

class ProfileScreen extends StatelessWidget { const ProfileScreen({super.key});

@override Widget build(BuildContext context) { final app = context.watch<AppProvider>(); final user = app.currentUser;

if (user == null) {
  return const Scaffold(body: Center(child: Text('Not signed in')));
}

final theme = Theme.of(context);

return Scaffold(
  body: SafeArea(
    child: Column(
      children: [
        // 🔥 Top Profile Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                user.email,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 🔥 Options Section
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _tile(
                context,
                icon: Icons.tune,
                title: 'Preferences',
                onTap: () {
                  // handle preferences
                },
              ),

              _tile(
                context,
                icon: Icons.bookmark,
                title: 'Saved Scholarships',
                onTap: () {},
              ),

              _tile(
                context,
                icon: Icons.account_balance,
                title: 'Saved Loans',
                onTap: () {},
              ),

              const SizedBox(height: 20),

              // 🔴 Logout Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  await app.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);

}

Widget _tile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) { return Card( shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: ListTile( leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: onTap, ), ); } }