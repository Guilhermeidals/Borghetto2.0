import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../theme/app_theme.dart';
import '../models/marketing_banner.dart';

class AdminMarketingScreen extends StatefulWidget {
  const AdminMarketingScreen({super.key});

  @override
  State<AdminMarketingScreen> createState() => _AdminMarketingScreenState();
}

class _AdminMarketingScreenState extends State<AdminMarketingScreen> {
  final ImagePicker _picker = ImagePicker();
  List<MarketingBanner> _banners = [];
  bool _isLoading = true;
  bool _isUploading = false;
  int? _updatingBannerId;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() => _isLoading = true);
    try {
      final banners = await ApiClient.instance.getMarketingBanners(admin: true);
      if (!mounted) return;
      setState(() => _banners = banners);
    } on ApiException catch (error) {
      _showMessage(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addBanner() async {
    if (_isUploading) return;

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
      maxWidth: 1800,
    );
    if (image == null || !mounted) return;

    final titleController = TextEditingController();
    final shouldUpload = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nova campanha'),
        content: TextField(
          controller: titleController,
          maxLength: 80,
          decoration: const InputDecoration(
            labelText: 'Título opcional',
            hintText: 'Ex.: Oferta especial da semana',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    final title = titleController.text;
    titleController.dispose();
    if (shouldUpload != true || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final banner = await ApiClient.instance.createMarketingBanner(
        imageFile: image,
        title: title,
      );
      if (!mounted) return;
      setState(() => _banners.add(banner));
      _showMessage('Campanha adicionada ao carrossel.');
    } on ApiException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Não foi possível enviar a imagem.', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _toggleBanner(MarketingBanner banner, bool active) async {
    setState(() {
      _updatingBannerId = banner.id;
      final index = _banners.indexWhere((item) => item.id == banner.id);
      if (index >= 0) _banners[index] = banner.copyWith(active: active);
    });

    try {
      await ApiClient.instance.updateMarketingBanner(
        bannerId: banner.id,
        active: active,
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          final index = _banners.indexWhere((item) => item.id == banner.id);
          if (index >= 0) _banners[index] = banner;
        });
      }
      _showMessage(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _updatingBannerId = null);
    }
  }

  Future<void> _deleteBanner(MarketingBanner banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir campanha?'),
        content: const Text(
          'A imagem será removida do painel e não aparecerá mais no aplicativo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _updatingBannerId = banner.id);
    try {
      await ApiClient.instance.deleteMarketingBanner(banner.id);
      if (!mounted) return;
      setState(() => _banners.removeWhere((item) => item.id == banner.id));
      _showMessage('Campanha excluída.');
    } on ApiException catch (error) {
      _showMessage(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _updatingBannerId = null);
    }
  }

  Future<DateTime?> _pickScheduleDateTime(DateTime? current) async {
    final now = DateTime.now();
    final initial = current?.toLocal() ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatScheduleDate(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  Future<void> _editBanner(MarketingBanner banner) async {
    final titleController = TextEditingController(text: banner.title ?? '');
    var startsAt = banner.startsAt?.toLocal();
    var endsAt = banner.endsAt?.toLocal();
    String? scheduleError;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar campanha'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Deixe vazio para remover o título',
                  ),
                ),
                _ScheduleField(
                  label: 'Início da exibição',
                  value: startsAt == null
                      ? 'Exibir imediatamente'
                      : _formatScheduleDate(startsAt!),
                  onPick: () async {
                    final selected = await _pickScheduleDateTime(startsAt);
                    if (selected != null) {
                      setDialogState(() {
                        startsAt = selected;
                        scheduleError = null;
                      });
                    }
                  },
                  onClear: startsAt == null
                      ? null
                      : () => setDialogState(() {
                            startsAt = null;
                            scheduleError = null;
                          }),
                ),
                const SizedBox(height: 10),
                _ScheduleField(
                  label: 'Fim da exibição',
                  value: endsAt == null
                      ? 'Sem data de término'
                      : _formatScheduleDate(endsAt!),
                  onPick: () async {
                    final selected = await _pickScheduleDateTime(endsAt);
                    if (selected != null) {
                      setDialogState(() {
                        endsAt = selected;
                        scheduleError = null;
                      });
                    }
                  },
                  onClear: endsAt == null
                      ? null
                      : () => setDialogState(() {
                            endsAt = null;
                            scheduleError = null;
                          }),
                ),
                if (scheduleError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    scheduleError!,
                    style: const TextStyle(color: AppTheme.error),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (startsAt != null &&
                    endsAt != null &&
                    !endsAt!.isAfter(startsAt!)) {
                  setDialogState(() {
                    scheduleError = 'O término deve ser posterior ao início.';
                  });
                  return;
                }
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    final title = titleController.text;
    titleController.dispose();
    if (shouldSave != true || !mounted) return;

    setState(() => _updatingBannerId = banner.id);
    try {
      final updatedBanner = await ApiClient.instance.editMarketingBanner(
        bannerId: banner.id,
        title: title,
        startsAt: startsAt,
        endsAt: endsAt,
      );
      if (!mounted) return;

      setState(() {
        final index = _banners.indexWhere((item) => item.id == banner.id);
        if (index >= 0) _banners[index] = updatedBanner;
      });
      _showMessage('Campanha atualizada.');
    } on ApiException catch (error) {
      _showMessage(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _updatingBannerId = null);
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final previous = List<MarketingBanner>.from(_banners);
    setState(() {
      final item = _banners.removeAt(oldIndex);
      _banners.insert(newIndex, item);
    });

    try {
      await ApiClient.instance.reorderMarketingBanners(
        _banners.map((banner) => banner.id).toList(),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _banners = previous);
      _showMessage(error.message, isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppTheme.error : AppTheme.success,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'Marketing',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            color: AppTheme.darkText,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadBanners,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _addBanner,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: _isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_photo_alternate_outlined),
        label: Text(_isUploading ? 'Enviando...' : 'Adicionar imagem'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _banners.isEmpty
              ? _buildEmptyState()
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  itemCount: _banners.length,
                  onReorder: _reorder,
                  itemBuilder: (context, index) {
                    final banner = _banners[index];
                    return _BannerAdminCard(
                      key: ValueKey(banner.id),
                      banner: banner,
                      busy: _updatingBannerId == banner.id,
                      onActiveChanged: (active) =>
                          _toggleBanner(banner, active),
                      onEdit: () => _editBanner(banner),
                      onDelete: () => _deleteBanner(banner),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.campaign_outlined,
              size: 54,
              color: AppTheme.mutedText,
            ),
            const SizedBox(height: 14),
            Text(
              'Nenhuma campanha cadastrada',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Adicione imagens para exibi-las no carrossel da tela inicial.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppTheme.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleField extends StatelessWidget {
  const _ScheduleField({
    required this.label,
    required this.value,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.outlineLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              tooltip: 'Limpar',
              icon: const Icon(Icons.close_rounded),
            ),
          IconButton(
            onPressed: onPick,
            tooltip: 'Escolher data e hora',
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
    );
  }
}

class _BannerAdminCard extends StatelessWidget {
  const _BannerAdminCard({
    required super.key,
    required this.banner,
    required this.busy,
    required this.onActiveChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final MarketingBanner banner;
  final bool busy;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiClient.instance.resolveFileUrl(banner.imageUrl);
    final startDescription = _startDescription();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 7,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const ColoredBox(
                color: AppTheme.surfaceVariantLight,
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              banner.title?.trim().isNotEmpty == true
                                  ? banner.title!
                                  : 'Campanha sem título',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (banner.endsAt != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariantLight,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Fim: ${_formatCardDate(banner.endsAt!)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.mutedText,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (startDescription != null)
                        Text(
                          startDescription,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.mutedText,
                          ),
                        ),
                    ],
                  ),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  Switch.adaptive(
                    value: banner.active,
                    activeThumbColor: AppTheme.success,
                    onChanged: onActiveChanged,
                  ),
                IconButton(
                  onPressed: busy ? null : onDelete,
                  tooltip: 'Excluir',
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppTheme.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _startDescription() {
    if (banner.startsAt != null) {
      return 'Início: ${_formatCardDate(banner.startsAt!)}';
    }
    return null;
  }

  String _formatCardDate(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(local.day)}/${twoDigits(local.month)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}
