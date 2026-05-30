import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class AccessLogScreen extends StatefulWidget {
  const AccessLogScreen({super.key});

  @override
  State<AccessLogScreen> createState() => _AccessLogScreenState();
}

class _AccessLogScreenState extends State<AccessLogScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Entry', 'Exit', 'Denied'];

  final List<Map<String, dynamic>> _logs = [
    {
      'type': 'Entry',
      'location': 'Main Entrance — Gate A',
      'date': 'Today',
      'time': '09:14 AM',
      'method': 'Face ID',
      'status': 'granted',
      'points': '+5',
    },
    {
      'type': 'Exit',
      'location': 'Main Entrance — Gate A',
      'date': 'Today',
      'time': '11:42 AM',
      'method': 'QR Code',
      'status': 'granted',
      'points': null,
    },
    {
      'type': 'Entry',
      'location': 'Members Lounge',
      'date': 'Today',
      'time': '11:45 AM',
      'method': 'Face ID',
      'status': 'granted',
      'points': '+10',
    },
    {
      'type': 'Exit',
      'location': 'Members Lounge',
      'date': 'Today',
      'time': '12:30 PM',
      'method': 'QR Code',
      'status': 'granted',
      'points': null,
    },
    {
      'type': 'Entry',
      'location': 'Premium Section — B2',
      'date': 'Yesterday',
      'time': '03:22 PM',
      'method': 'Face ID',
      'status': 'granted',
      'points': '+5',
    },
    {
      'type': 'Entry',
      'location': 'Staff Only — Storage',
      'date': 'Yesterday',
      'time': '03:25 PM',
      'method': 'Face ID',
      'status': 'denied',
      'points': null,
    },
    {
      'type': 'Exit',
      'location': 'Main Entrance — Gate A',
      'date': 'Yesterday',
      'time': '05:10 PM',
      'method': 'QR Code',
      'status': 'granted',
      'points': null,
    },
    {
      'type': 'Entry',
      'location': 'Main Entrance — Gate A',
      'date': 'May 26',
      'time': '10:05 AM',
      'method': 'Face ID',
      'status': 'granted',
      'points': '+5',
    },
    {
      'type': 'Entry',
      'location': 'Members Lounge',
      'date': 'May 26',
      'time': '10:12 AM',
      'method': 'QR Code',
      'status': 'granted',
      'points': '+10',
    },
    {
      'type': 'Exit',
      'location': 'Main Entrance — Gate A',
      'date': 'May 26',
      'time': '01:48 PM',
      'method': 'QR Code',
      'status': 'granted',
      'points': null,
    },
    {
      'type': 'Entry',
      'location': 'Main Entrance — Gate A',
      'date': 'May 24',
      'time': '08:55 AM',
      'method': 'Face ID',
      'status': 'granted',
      'points': '+5',
    },
    {
      'type': 'Entry',
      'location': 'Premium Section — B2',
      'date': 'May 24',
      'time': '09:10 AM',
      'method': 'Face ID',
      'status': 'denied',
      'points': null,
    },
  ];

  List<Map<String, dynamic>> get _filteredLogs {
    if (_selectedFilter == 0) return _logs;
    final filter = _filters[_selectedFilter];
    return _logs.where((log) {
      if (filter == 'Denied') return log['status'] == 'denied';
      return log['type'] == filter;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _groupedLogs {
    final filtered = _filteredLogs;
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final log in filtered) {
      final date = log['date'] as String;
      grouped.putIfAbsent(date, () => []).add(log);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildSummaryRow(),
            _buildFilterChips(),
            Expanded(child: _buildLogList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Text(
            'Access Log',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.download_outlined,
                size: 18,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    final granted = _logs.where((l) => l['status'] == 'granted').length;
    final denied = _logs.where((l) => l['status'] == 'denied').length;
    final totalPoints = _logs.where((l) => l['points'] != null).fold<int>(0, (
      sum,
      l,
    ) {
      final pts =
          int.tryParse((l['points'] as String).replaceAll('+', '')) ?? 0;
      return sum + pts;
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryChip(
              '$granted',
              'Granted',
              AppTheme.accent,
              AppTheme.accentLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryChip(
              '$denied',
              'Denied',
              AppTheme.error,
              AppTheme.error.withAlpha(20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryChip(
              '+$totalPoints',
              'Points',
              const Color(0xFFE8A020),
              const Color(0xFFFFF3E0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String value, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: color.withAlpha(204),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 0, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_filters.length, (i) {
            final isSelected = i == _selectedFilter;
            return Padding(
              padding: EdgeInsets.only(right: i < _filters.length - 1 ? 8 : 24),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.outlineLight,
                    ),
                  ),
                  child: Text(
                    _filters[i],
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.mutedText,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLogList() {
    final grouped = _groupedLogs;
    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 48,
              color: AppTheme.mutedText.withAlpha(102),
            ),
            const SizedBox(height: 12),
            Text(
              'No records found',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Text(
                entry.key,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedText,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Column(
                children: List.generate(entry.value.length, (i) {
                  final log = entry.value[i];
                  return Column(
                    children: [
                      _buildLogItem(log),
                      if (i < entry.value.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppTheme.outlineLight,
                          indent: 60,
                        ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final isGranted = log['status'] == 'granted';
    final isEntry = log['type'] == 'Entry';

    final statusColor = isGranted ? AppTheme.accent : AppTheme.error;
    final statusBg = isGranted
        ? AppTheme.accentLight
        : AppTheme.error.withAlpha(20);
    final typeIcon = isEntry ? Icons.login_rounded : Icons.logout_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(typeIcon, size: 18, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['location'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      log['time'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppTheme.mutedText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      log['method'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  isGranted ? 'Granted' : 'Denied',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              if (log['points'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  log['points'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
