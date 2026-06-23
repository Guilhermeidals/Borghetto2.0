import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/image_upload_helper.dart';
import '../models/app_dependent.dart';
import '../widgets/dependent_form_sheet.dart';


enum DependentFilter {
  active,
  inactive,
  all,
}

class DependentsScreen extends StatefulWidget {
  const DependentsScreen({super.key});

  @override
  State<DependentsScreen> createState() => _DependentsScreenState();
}

class _DependentsScreenState extends State<DependentsScreen> {
  final List<AppDependent> _dependents = [];
 
  bool _isLoading = true;
  bool _isSaving = false;

  int? _userId;

  DependentFilter _filter = DependentFilter.active;

  @override
  void initState() {
    super.initState();
    _loadDependents();
  }

  List<AppDependent> get _filteredDependents {
    switch (_filter) {
      case DependentFilter.active:
        return _dependents.where((item) => item.active).toList();

      case DependentFilter.inactive:
        return _dependents.where((item) => !item.active).toList();

      case DependentFilter.all:
        return List<AppDependent>.from(_dependents);
    }
  }

  String get _filterLabel {
    switch (_filter) {
      case DependentFilter.active:
        return 'Ativos';

      case DependentFilter.inactive:
        return 'Inativos';

      case DependentFilter.all:
        return 'Todos';
    }
  }

  Future<void> _openCreateDependentSheet() async {
    if (_isSaving) return;

    final userId = _userId;

    if (userId == null) {
      _showErrorMessage('Sessão expirada. Faça login novamente.');
      return;
    }

    final result = await showModalBottomSheet<DependentFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return const DependentFormSheet();
      },
    );

    if (result == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final createdDependent = await ApiClient.instance.createDependent(
        userId: userId,
        name: result.dependent.name,
        cpf: result.dependent.cpf,
        birthDate: result.dependent.birthDate,
        relationship: result.dependent.relationship,
      );

      if (!mounted) return;

      setState(() {
        _dependents.add(createdDependent);
        _isSaving = false;
      });

      _showSuccessMessage('Familiar adicionado com sucesso');
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showErrorMessage(e.message);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showErrorMessage('Erro ao adicionar familiar');
    }
  }

  Future<void> _openEditDependentSheet(AppDependent dependent) async {
    if (_isSaving) return;

    final userId = _userId;

    if (userId == null) {
      _showErrorMessage('Sessão expirada. Faça login novamente.');
      return;
    }

    final result = await showModalBottomSheet<DependentFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DependentFormSheet(
          dependent: dependent,
        );
      },
    );

    if (result == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedDependent = await ApiClient.instance.updateDependent(
        userId: userId,
        dependentId: dependent.id,
        name: result.dependent.name,
        cpf: result.dependent.cpf,
        birthDate: result.dependent.birthDate,
        relationship: result.dependent.relationship,
        active: result.dependent.active,
      );

      if (result.faceImage != null) {
        final preparedImage = await ImageUploadHelper.prepareFileForUpload(
          result.faceImage!,
        );

        await ApiClient.instance.uploadDependentFace(
          userId: userId,
          dependentId: dependent.id,
          imageFile: preparedImage,
        );
      }

      if (result.faceImage != null) {
        await ApiClient.instance.uploadDependentFace(
          userId: userId,
          dependentId: dependent.id,
          imageFile: result.faceImage!,
        );

        await _loadDependents();
      }

      if (!mounted) return;

      setState(() {
        final index = _dependents.indexWhere((item) => item.id == dependent.id);

        if (index >= 0) {
          _dependents[index] = updatedDependent;
        }

        _isSaving = false;
      });

      _showSuccessMessage('Familiar atualizado com sucesso');
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showErrorMessage(e.message);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showErrorMessage('Erro ao atualizar familiar');
    }
  }

  Future<void> _confirmRemoveDependent(AppDependent dependent) async {
    if (_isSaving) return;

    final userId = _userId;

    if (userId == null) {
      _showErrorMessage('Sessão expirada. Faça login novamente.');
      return;
    }

    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover familiar?'),
          content: Text(
            'Deseja remover ${dependent.name} da sua lista de familiares?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiClient.instance.deleteDependent(
        userId: userId,
        dependentId: dependent.id,
      );

      if (!mounted) return;

      setState(() {
        _dependents.removeWhere((item) => item.id == dependent.id);
        _isSaving = false;
      });

      _showSuccessMessage('Familiar removido');
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showErrorMessage(e.message);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showErrorMessage('Erro ao remover familiar');
    }
  }

  Future<void> _loadDependents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final session = await ApiClient.instance.getSavedSession();
      final userId = session?.userId;

      if (userId == null || userId <= 0) {
        throw ApiException('Sessão expirada. Faça login novamente.');
      }

      final dependents = await ApiClient.instance.getDependents(userId);

      if (!mounted) return;

      setState(() {
        _userId = userId;
        _dependents
          ..clear()
          ..addAll(dependents);
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showErrorMessage(e.message);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showErrorMessage('Erro ao carregar familiares');
    }
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeDependents = _dependents.where((item) => item.active).length;
    final filteredDependents = _filteredDependents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Familiares'),
      ),
        body: _isLoading
    ? const Center(
        child: CircularProgressIndicator(),
      )
    : _dependents.isEmpty
        ? _EmptyDependentsState(
            onAddPressed: _openCreateDependentSheet,
          )
        : RefreshIndicator(
            onRefresh: _loadDependents,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _DependentsHeaderCard(
                  total: _dependents.length,
                  active: activeDependents,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lista de familiares',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    _DependentFilterDropdown(
                      selectedFilter: _filter,
                      label: _filterLabel,
                      onChanged: (filter) {
                        setState(() {
                          _filter = filter;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (filteredDependents.isEmpty)
                  _EmptyFilteredDependentsState(
                    filter: _filter,
                  )
                else
                  ...filteredDependents.map(
                    (dependent) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DependentCard(
                          dependent: dependent,
                          onEdit: () => _openEditDependentSheet(dependent),
                          onRemove: () => _confirmRemoveDependent(dependent),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading || _isSaving ? null : _openCreateDependentSheet,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.person_add_alt_1_rounded),
        label: Text(_isSaving ? 'Salvando...' : 'Adicionar'),
      ),
    );
  }
}

class _DependentsHeaderCard extends StatelessWidget {
  const _DependentsHeaderCard({
    required this.total,
    required this.active,
  });

  final int total;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.family_restroom_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Familiares cadastrados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$active ativo(s) de $total cadastro(s)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DependentCard extends StatelessWidget {
  const _DependentCard({
    required this.dependent,
    required this.onEdit,
    required this.onRemove,
  });

  final AppDependent dependent;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _DependentAvatar(
                dependent: dependent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dependent.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dependent.relationshipLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'CPF: ${dependent.formattedCpf}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Nascimento: ${dependent.birthDate}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _StatusChip(active: dependent.active),
                        if (dependent.active && !dependent.faceRegistered)
                          const _FacePendingChip(),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  }

                  if (value == 'remove') {
                    onRemove();
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar'),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Remover'),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DependentAvatar extends StatelessWidget {
  const _DependentAvatar({
    required this.dependent,
  });

  final AppDependent dependent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controlIdUserId = dependent.controlIdUserId ?? 0;

    final hasPhoto =
        dependent.active && dependent.faceRegistered && controlIdUserId > 0;

    if (!hasPhoto) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: dependent.active
            ? colorScheme.primaryContainer
            : Colors.grey.shade200,
        child: Icon(
          Icons.person_rounded,
          color: dependent.active ? colorScheme.primary : Colors.grey.shade600,
        ),
      );
    }

    return FutureBuilder<Uint8List>(
      future: ApiClient.instance.getFacialUserPhotoBytes(controlIdUserId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'ERRO FOTO DEPENDENTE => '
            'nome=${dependent.name}, '
            'controlIdUserId=$controlIdUserId, '
            'erro=${snapshot.error}',
          );
        }

        if (snapshot.hasData) {
          return CircleAvatar(
            radius: 26,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: MemoryImage(snapshot.data!),
          );
        }

        return CircleAvatar(
          radius: 26,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.person_rounded,
            color: colorScheme.primary,
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.active,
  });

  final bool active;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = active ? Colors.green.shade50 : Colors.red.shade50;
    final textColor = active ? Colors.green.shade800 : Colors.red.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Ativo' : 'Inativo',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _EmptyDependentsState extends StatelessWidget {
  const _EmptyDependentsState({
    required this.onAddPressed,
  });

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.family_restroom_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              'Nenhum familiar cadastrado',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione cônjuge, filhos ou outros familiares para preparar o acesso deles ao clube.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Adicionar familiar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DependentFilterDropdown extends StatelessWidget {
  const _DependentFilterDropdown({
    required this.selectedFilter,
    required this.label,
    required this.onChanged,
  });

  final DependentFilter selectedFilter;
  final String label;
  final ValueChanged<DependentFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<DependentFilter>(
      initialValue: selectedFilter,
      tooltip: 'Filtrar familiares',
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      itemBuilder: (context) {
        return const [
          PopupMenuItem(
            value: DependentFilter.active,
            child: Text('Ativos'),
          ),
          PopupMenuItem(
            value: DependentFilter.inactive,
            child: Text('Inativos'),
          ),
          PopupMenuItem(
            value: DependentFilter.all,
            child: Text('Todos'),
          ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFilteredDependentsState extends StatelessWidget {
  const _EmptyFilteredDependentsState({
    required this.filter,
  });

  final DependentFilter filter;

  String get _title {
    switch (filter) {
      case DependentFilter.active:
        return 'Nenhum familiar ativo';

      case DependentFilter.inactive:
        return 'Nenhum familiar inativo';

      case DependentFilter.all:
        return 'Nenhum familiar encontrado';
    }
  }

  String get _subtitle {
    switch (filter) {
      case DependentFilter.active:
        return 'Familiares desativados não aparecem neste filtro.';

      case DependentFilter.inactive:
        return 'Quando um familiar for desativado, ele aparecerá aqui.';

      case DependentFilter.all:
        return 'Nenhum familiar disponível para exibição.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.filter_alt_off_rounded,
            size: 42,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 12),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
        ],
      ),
    );
  }
}

class _FacePendingChip extends StatelessWidget {
  const _FacePendingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.orange.shade200,
        ),
      ),
      child: Text(
        'Sem foto',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.orange.shade900,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}