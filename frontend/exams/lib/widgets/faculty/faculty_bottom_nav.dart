import 'package:flutter/material.dart';

class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return const BottomAppBar(
      height: 82,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      notchMargin: 8,
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          NavItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            selected: true,
          ),
          NavItem(
            icon: Icons.people_alt_outlined,
            label: 'Roster',
          ),
          SizedBox(width: 54),
          NavItem(
            icon: Icons.error_outline_rounded,
            label: 'Incidents',
          ),
          NavItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF4560BD) : const Color(0xFF98A7BF);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 29),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
