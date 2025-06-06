import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminAccessWidget extends StatelessWidget {
  const AdminAccessWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.go('/admin-login'),
      icon: const Icon(Icons.admin_panel_settings),
      tooltip: 'Admin Access',
    );
  }
}
