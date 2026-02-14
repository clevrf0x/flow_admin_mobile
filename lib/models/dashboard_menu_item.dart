// lib/models/dashboard_menu_item.dart

import 'package:flutter/material.dart';

enum DashboardSection {
  operations,
  reports,
  others,
  settings,
}

class DashboardMenuItem {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final DashboardSection section;
  final String route;

  const DashboardMenuItem({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.section,
    required this.route,
  });
}

/// Main dashboard menu items
/// Others is its own standalone entry — not grouped under Reports
const List<DashboardMenuItem> dashboardMenuItems = [
  // === OPERATIONS ===
  DashboardMenuItem(
    id: 'booking',
    label: 'Booking',
    subtitle: 'Place and manage bets',
    icon: Icons.receipt_long_rounded,
    section: DashboardSection.operations,
    route: '/booking',
  ),
  DashboardMenuItem(
    id: 'monitor',
    label: 'Monitor',
    subtitle: 'Live draw monitoring',
    icon: Icons.monitor_heart_rounded,
    section: DashboardSection.operations,
    route: '/monitor',
  ),
  DashboardMenuItem(
    id: 'today',
    label: 'Today',
    subtitle: "Today's summary",
    icon: Icons.today_rounded,
    section: DashboardSection.operations,
    route: '/today',
  ),
  DashboardMenuItem(
    id: 'add_results',
    label: 'Add Results',
    subtitle: 'Enter draw results',
    icon: Icons.add_chart_rounded,
    section: DashboardSection.operations,
    route: '/add-results',
  ),

  // === REPORTS ===
  DashboardMenuItem(
    id: 'daily_report',
    label: 'Daily Report',
    subtitle: 'Full day breakdown',
    icon: Icons.bar_chart_rounded,
    section: DashboardSection.reports,
    route: '/daily-report',
  ),
  DashboardMenuItem(
    id: 'sales_report',
    label: 'Sales Report',
    subtitle: 'Revenue and sales data',
    icon: Icons.trending_up_rounded,
    section: DashboardSection.reports,
    route: '/sales-report',
  ),
  DashboardMenuItem(
    id: 'monitor_report',
    label: 'Monitor Report',
    subtitle: 'Monitoring history',
    icon: Icons.assessment_rounded,
    section: DashboardSection.reports,
    route: '/monitor-report',
  ),

  // === OTHERS (standalone section) ===
  DashboardMenuItem(
    id: 'others',
    label: 'Others',
    subtitle: 'Additional tools & reports',
    icon: Icons.folder_open_rounded,
    section: DashboardSection.others,
    route: '/others',
  ),

  // === SETTINGS ===
  DashboardMenuItem(
    id: 'change_password',
    label: 'Change Password',
    subtitle: 'Update your credentials',
    icon: Icons.lock_reset_rounded,
    section: DashboardSection.settings,
    route: '/change-password',
  ),
  DashboardMenuItem(
    id: 'change_game',
    label: 'Change Game',
    subtitle: 'Switch to another game',
    icon: Icons.swap_horiz_rounded,
    section: DashboardSection.settings,
    route: '/change-game',
  ),
];

extension DashboardSectionLabel on DashboardSection {
  String get label {
    switch (this) {
      case DashboardSection.operations:
        return 'OPERATIONS';
      case DashboardSection.reports:
        return 'REPORTS';
      case DashboardSection.others:
        return 'OTHERS';
      case DashboardSection.settings:
        return 'SETTINGS';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OTHERS SUB-PAGE ITEMS
// ─────────────────────────────────────────────────────────────────────────────

class OthersMenuItem {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;

  const OthersMenuItem({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

const List<OthersMenuItem> othersMenuItems = [
  OthersMenuItem(
    id: 'blocked_numbers',
    label: 'Blocked Numbers',
    subtitle: 'View and manage blocked entries',
    icon: Icons.block_rounded,
  ),
  OthersMenuItem(
    id: 'customer',
    label: 'Customer',
    subtitle: 'Customer management',
    icon: Icons.people_alt_rounded,
  ),
  OthersMenuItem(
    id: 'settings',
    label: 'Settings',
    subtitle: 'Game configuration',
    icon: Icons.settings_rounded,
  ),
  OthersMenuItem(
    id: 'results',
    label: 'Results',
    subtitle: 'View draw results',
    icon: Icons.emoji_events_rounded,
  ),
  OthersMenuItem(
    id: 'daily_report_others',
    label: 'Daily Report',
    subtitle: 'Full day breakdown',
    icon: Icons.bar_chart_rounded,
  ),
  OthersMenuItem(
    id: 'count_sales_report',
    label: 'Count Sales Report',
    subtitle: 'Sales count analysis',
    icon: Icons.point_of_sale_rounded,
  ),
  OthersMenuItem(
    id: 'winning_report',
    label: 'Winning Report',
    subtitle: 'Winners and payouts',
    icon: Icons.workspace_premium_rounded,
  ),
  OthersMenuItem(
    id: 'count_winning_report',
    label: 'Count Winning Report',
    subtitle: 'Winning count analysis',
    icon: Icons.leaderboard_rounded,
  ),
  OthersMenuItem(
    id: 'deleted_numbers',
    label: 'Deleted Numbers',
    subtitle: 'Audit trail of deletions',
    icon: Icons.delete_sweep_rounded,
  ),
  OthersMenuItem(
    id: 'rejected_numbers',
    label: 'Rejected Numbers',
    subtitle: 'Rejected entry log',
    icon: Icons.cancel_rounded,
  ),
];
