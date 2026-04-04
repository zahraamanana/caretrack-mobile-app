import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/nurse.dart';
import '../providers/nurse_provider.dart';
import '../widgets/language_selector_button.dart';

class NurseManagementScreen extends StatefulWidget {
  const NurseManagementScreen({super.key});

  @override
  State<NurseManagementScreen> createState() => _NurseManagementScreenState();
}

class _NurseManagementScreenState extends State<NurseManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NurseProvider>().loadNurses(showLoading: false);
    });
  }

  Future<void> _openNurseSheet({Nurse? nurse}) async {
    final nurseProvider = context.read<NurseProvider>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddNurseSheet(nurse: nurse),
    );

    if (saved == true) {
      await nurseProvider.loadNurses(showLoading: false);
    }
  }

  Future<void> _confirmDeleteNurse(Nurse nurse) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final nurseProvider = context.read<NurseProvider>();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteNurse),
          content: Text(l10n.deleteNurseConfirmation(nurse.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                l10n.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await nurseProvider.deleteNurse(nurse.id);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.nurseDeleteFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.deletedNurseMessage(nurse.name)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nurseProvider = context.watch<NurseProvider>();
    final l10n = AppLocalizations.of(context);
    const primaryColor = Color.fromARGB(255, 110, 101, 168);
    const accentColor = Color.fromARGB(255, 37, 101, 146);
    final nurses = nurseProvider.nurses;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: l10n.isArabic
            ? null
            : IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
        title: Text(l10n.nurseManagement),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _openNurseSheet(),
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
          const LanguageSelectorButton(iconColor: Colors.white),
          if (l10n.isArabic)
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_forward_rounded),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.nurseManagement,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.nurseManagementDescription,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.nurseCountLabel(nurses.length),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.nurseShiftOverview,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (nurseProvider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              ),
            )
          else if (nurseProvider.hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () => context.read<NurseProvider>().loadNurses(),
                  child: Text(l10n.tryAgain),
                ),
              ),
            )
          else if (nurses.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                l10n.noNursesYet,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            )
          else
            ...nurses.map(
              (nurse) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NurseTile(
                  nurse: nurse,
                  onEdit: () => _openNurseSheet(nurse: nurse),
                  onDelete: () => _confirmDeleteNurse(nurse),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NurseTile extends StatelessWidget {
  final Nurse nurse;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NurseTile({
    required this.nurse,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Text(
              nurse.name.isEmpty ? 'N' : nurse.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 110, 101, 168),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nurse.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.departmentFloorLabel(nurse.department, nurse.floor),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.nurseShiftLabel(nurse.shiftStart, nurse.shiftEnd),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                color: const Color.fromARGB(255, 110, 101, 168),
                tooltip: l10n.edit,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.red,
                tooltip: l10n.delete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddNurseSheet extends StatefulWidget {
  final Nurse? nurse;

  const _AddNurseSheet({this.nurse});

  @override
  State<_AddNurseSheet> createState() => _AddNurseSheetState();
}

class _AddNurseSheetState extends State<_AddNurseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shiftStartController = TextEditingController();
  final _shiftEndController = TextEditingController();
  String _selectedDepartment = 'Medical';
  String _selectedFloor = '1';
  bool _didPrefill = false;
  bool _isSaving = false;
  String? _saveError;

  static const List<String> _departments = [
    'Medical',
    'Surgery',
    'Pediatrics',
    'ICU',
  ];

  static const List<String> _floors = ['1', '2'];

  bool get _isEditing => widget.nurse != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefill || widget.nurse == null) return;

    final nurse = widget.nurse!;
    _nameController.text = nurse.name;
    _shiftStartController.text = nurse.shiftStart;
    _shiftEndController.text = nurse.shiftEnd;
    _selectedDepartment = nurse.department;
    _selectedFloor = nurse.floor;
    _didPrefill = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shiftStartController.dispose();
    _shiftEndController.dispose();
    super.dispose();
  }

  Future<void> _saveNurse() async {
    final l10n = AppLocalizations.of(context);
    final nurseProvider = context.read<NurseProvider>();
    final navigator = Navigator.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final currentNurse = widget.nurse;
    final nurse = Nurse(
      id: currentNurse?.id ?? 'nurse_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      floor: _selectedFloor,
      department: _selectedDepartment,
      shiftStart: _shiftStartController.text.trim(),
      shiftEnd: _shiftEndController.text.trim(),
    );

    try {
      if (_isEditing) {
        await nurseProvider.updateNurse(nurse);
      } else {
        await nurseProvider.addNurse(nurse);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = l10n.nurseSaveFailed;
      });
      return;
    }

    if (!mounted) return;
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const primaryColor = Color.fromARGB(255, 110, 101, 168);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEditing ? l10n.editNurse : l10n.addNewNurse,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 37, 101, 146),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.nurseManagementDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _NurseTextField(
                controller: _nameController,
                label: l10n.nurseName,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return l10n.enterNurseName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _NurseDropdownField(
                value: _selectedDepartment,
                label: l10n.department,
                items: _departments,
                itemLabelBuilder: (l10n, item) => l10n.departmentLabel(item),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedDepartment = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              _NurseDropdownField(
                value: _selectedFloor,
                label: l10n.floor,
                items: _floors,
                itemLabelBuilder: (l10n, item) => l10n.floorLabel(item),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedFloor = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _NurseTextField(
                      controller: _shiftStartController,
                      label: l10n.shiftStart,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return l10n.enterShiftStart;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NurseTextField(
                      controller: _shiftEndController,
                      label: l10n.shiftEnd,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return l10n.enterShiftEnd;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _saveError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveNurse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.saving,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : Text(
                        l10n.saveNurse,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NurseTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const _NurseTextField({
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F7FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _NurseDropdownField extends StatelessWidget {
  final String value;
  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String Function(AppLocalizations l10n, String item)? itemLabelBuilder;

  const _NurseDropdownField({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.itemLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          onChanged: onChanged,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(itemLabelBuilder?.call(l10n, item) ?? item),
                ),
              )
              .toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F7FB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
