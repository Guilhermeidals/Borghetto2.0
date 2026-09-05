import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../theme/app_theme.dart';

class AccessLogScreen extends StatefulWidget {
  const AccessLogScreen({super.key});

  @override
  State<AccessLogScreen> createState() => _AccessLogScreenState();
}

class _AccessLogScreenState extends State<AccessLogScreen> {
  int _selectedFilter = 0;

  final List<String> _filters = [
    'Todos',
    'Liberados',
    'Negados',
    'Titular',
    'Dependentes',
  ];

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadAccessLogs();
  }

  Future<void> _loadAccessLogs({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final logs = await ApiClient.instance.getAccessLogs();

      if (!mounted) {
        return;
      }

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Erro ao carregar histórico de acessos';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_selectedFilter == 0) {
      return _logs;
    }

    return _logs.where((log) {
      final event = int.tryParse(log['event']?.toString() ?? '');
      final personType = log['person_type']?.toString().toLowerCase();

      switch (_selectedFilter) {
        case 1:
          return _isGrantedEvent(event);
        case 2:
          return _isDeniedEvent(event);
        case 3:
          return personType == 'titular';
        case 4:
          return personType == 'dependente';
        default:
          return true;
      }
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _groupedLogs {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final log in _filteredLogs) {
      final group = _formatDateGroup(log['access_time']);
      grouped.putIfAbsent(group, () => []).add(log);
    }

    return grouped;
  }

  bool _isGrantedEvent(int? event) {
    return event == 7 ||
        event == 10 ||
        event == 11 ||
        event == 12 ||
        event == 15;
  }

  bool _isDeniedEvent(int? event) {
    return event == 1 ||
        event == 2 ||
        event == 3 ||
        event == 5 ||
        event == 6 ||
        event == 9;
  }

  String _formatDateGroup(dynamic value) {
    if (value == null) {
      return 'Data não informada';
    }

    try {
      final date = DateTime.parse(value.toString()).toLocal();
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);
      final logDay = DateTime(date.year, date.month, date.day);
      final difference = today.difference(logDay).inDays;

      if (difference == 0) {
        return 'Hoje';
      }

      if (difference == 1) {
        return 'Ontem';
      }

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      return '$day/$month/$year';
    } catch (_) {
      return 'Data não informada';
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) {
      return '--:--';
    }

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$hour:$minute';
    } catch (_) {
      return '--:--';
    }
  }

  String _formatPersonType(dynamic value) {
    final type = value?.toString().toLowerCase();

    if (type == 'titular') {
      return 'Titular';
    }

    if (type == 'dependente') {
      return 'Dependente';
    }

    return 'Usuário';
  }

  String _formatAccessLabel(Map<String, dynamic> log) {
    final label = log['event_label']?.toString().trim();

    if (label != null && label.isNotEmpty) {
      return label;
    }

    final event = int.tryParse(log['event']?.toString() ?? '');

    if (_isDeniedEvent(event)) {
      return 'Acesso negado';
    }

    if (_isGrantedEvent(event)) {
      return 'Acesso liberado';
    }

    return 'Acesso via App';
  }

  Color _statusColor(Map<String, dynamic> log) {
    final event = int.tryParse(log['event']?.toString() ?? '');

    if (_isDeniedEvent(event)) {
      return AppTheme.error;
    }

    if (_isGrantedEvent(event)) {
      return AppTheme.accent;
    }

    return AppTheme.mutedText;
  }

  IconData _statusIcon(Map<String, dynamic> log) {
    final event = int.tryParse(log['event']?.toString() ?? '');

    if (_isDeniedEvent(event)) {
      return Icons.block_rounded;
    }

    if (_isGrantedEvent(event)) {
      return Icons.check_circle_rounded;
    }

    return Icons.history_rounded;
  }

  int get _grantedCount {
    return _logs.where((log) {
      final event = int.tryParse(log['event']?.toString() ?? '');
      return _isGrantedEvent(event);
    }).length;
  }

  int get _deniedCount {
    return _logs.where((log) {
      final event = int.tryParse(log['event']?.toString() ?? '');
      return _isDeniedEvent(event);
    }).length;
  }

  int get _dependentsCount {
    return _logs.where((log) {
      return log['person_type']?.toString().toLowerCase() == 'dependente';
    }).length;
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
            _buildHeader(),
            _buildSummaryTitle(),
            _buildSummaryRow(),
            _buildFilterChips(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Text(
            'Histórico de acessos',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _loadAccessLogs,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Text(
        'Últimos 100 acessos',
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.mutedText,
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryChip(
              '$_grantedCount',
              'Liberados',
              AppTheme.accent,
              AppTheme.accentLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryChip(
              '$_deniedCount',
              'Negados',
              AppTheme.error,
              AppTheme.error.withAlpha(20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryChip(
              '$_dependentsCount',
              'Familiares',
              AppTheme.primary,
              AppTheme.forestMist,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(
    String value,
    String label,
    Color color,
    Color bg,
  ) {
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
              padding: EdgeInsets.only(
                right: i < _filters.length - 1 ? 8 : 24,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = i;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppTheme.primary : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color:
                          isSelected ? AppTheme.primary : AppTheme.outlineLight,
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () => _loadAccessLogs(showLoading: false),
      child: _buildLogList(),
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: AppTheme.error.withAlpha(220),
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage ?? 'Erro ao carregar histórico de acessos',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: _loadAccessLogs,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tentar novamente'),
          ),
        ),
      ],
    );
  }

  Widget _buildLogList() {
    final grouped = _groupedLogs;

    if (grouped.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
        children: [
          Icon(
            Icons.history_rounded,
            size: 48,
            color: AppTheme.mutedText.withAlpha(102),
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum acesso encontrado',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Quando houver registros na portaria, eles aparecerão aqui.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
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
            Column(
              children: List.generate(entry.value.length, (i) {
                final log = entry.value[i];

                return _buildLogItem(log);
              }),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final statusColor = _statusColor(log);
    final statusBg = statusColor.withAlpha(24);

    final personName = log['person_name']?.toString().trim();
    final displayName =
        personName == null || personName.isEmpty ? 'Usuário' : personName;

    final personType = _formatPersonType(log['person_type']);
    final accessLabel = _formatAccessLabel(log);
    final accessTime = _formatTime(log['access_time']);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineLight,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPersonPhoto(
                      log: log,
                      displayName: displayName,
                      statusColor: statusColor,
                      statusBg: statusBg,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.darkText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _statusIcon(log),
                                      size: 13,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      accessLabel,
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 15,
                                color: AppTheme.mutedText.withAlpha(210),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                accessTime,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.darkText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _logPill(
                                icon: Icons.person_outline_rounded,
                                label: personType,
                              ),
                              _logPill(
                                icon: Icons.sensor_door_outlined,
                                label: 'Entrada',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonPhoto({
    required Map<String, dynamic> log,
    required String displayName,
    required Color statusColor,
    required Color statusBg,
  }) {
    final photoUrl = log['person_photo_url']?.toString().trim();

    if (photoUrl == null || photoUrl.isEmpty) {
      return _buildInitialsAvatar(
        displayName: displayName,
        statusColor: statusColor,
        statusBg: statusBg,
      );
    }

    final imageUrl = ApiClient.instance.resolveFileUrl(photoUrl);

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withAlpha(40),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _buildInitialsAvatar(
            displayName: displayName,
            statusColor: statusColor,
            statusBg: statusBg,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInitialsAvatar({
    required String displayName,
    required Color statusColor,
    required Color statusBg,
  }) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withAlpha(40),
        ),
      ),
      child: Center(
        child: Text(
          _initials(displayName),
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: statusColor,
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  Widget _logPill({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.outlineLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: AppTheme.mutedText,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
