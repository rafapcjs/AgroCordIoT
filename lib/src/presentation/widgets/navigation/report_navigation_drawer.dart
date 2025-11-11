import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class ReportNavigationItem {
  const ReportNavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class ReportNavigationDrawer extends StatelessWidget {
  const ReportNavigationDrawer({
    super.key,
    required this.items,
    this.selectedLabel,
  });

  final List<ReportNavigationItem> items;
  final String? selectedLabel;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: DrawerHeader(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.analytics_outlined, color: Colors.white, size: 36),
                    SizedBox(height: 12),
                    Text(
                      'Reportes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Selecciona una vista',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  selected: item.label == selectedLabel,
                  selectedTileColor: AppTheme.primaryBlue.withOpacity(0.08),
                  leading: Icon(item.icon, color: AppTheme.primaryBlue),
                  title: Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    item.onTap();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
