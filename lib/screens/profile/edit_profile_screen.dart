import 'package:flutter/material.dart';

import '../../core/api_config.dart';
import '../../core/auth/session_controller.dart';
import '../../core/auth/validators.dart';
import '../../core/profile/profile_models.dart';
import '../../main.dart';
import '../../widgets/auth/app_text_field.dart';
import '../../widgets/ui_kit.dart';

const int _kMaxListItems = 30; // mirrors backend app/schemas/profile.py

class EditProfileScreen extends StatefulWidget {
  final ProfileData initialProfile;

  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  final List<_EducationDraft> _educationDrafts = [];
  final List<_ExperienceDraft> _experienceDrafts = [];
  late List<String> _skills;
  late List<String> _careerInterests;

  final _skillInputController = TextEditingController();
  final _interestInputController = TextEditingController();

  String? _formError;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameController = TextEditingController(text: p.fullName);
    _educationDrafts.addAll(p.education.map((e) => _EducationDraft(from: e)));
    _experienceDrafts.addAll(p.experience.map((e) => _ExperienceDraft(from: e)));
    _skills = List.of(p.skills);
    _careerInterests = List.of(p.careerInterests);
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final d in _educationDrafts) {
      d.dispose();
    }
    for (final d in _experienceDrafts) {
      d.dispose();
    }
    _skillInputController.dispose();
    _interestInputController.dispose();
    super.dispose();
  }

  void _addSkill(String Function() readAndClear, List<String> target) {
    final raw = readAndClear();
    final value = raw.trim();
    if (value.isEmpty) return;
    if (target.any((s) => s.toLowerCase() == value.toLowerCase())) return;
    if (target.length >= _kMaxListItems) return;
    setState(() => target.add(value));
  }

  Future<void> _save() async {
    setState(() => _formError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final session = SessionScope.of(context);
    final token = session.token;
    if (token == null) {
      setState(() => _formError = 'Your session has expired. Please log in again.');
      return;
    }

    final educationItems =
        _educationDrafts.map((d) => d.toItemOrNull()).whereType<EducationItem>().toList();
    final experienceItems =
        _experienceDrafts.map((d) => d.toItemOrNull()).whereType<ExperienceItem>().toList();

    final update = ProfileUpdate(
      fullName: _nameController.text.trim(),
      education: educationItems,
      skills: _skills,
      experience: experienceItems,
      careerInterests: _careerInterests,
    );

    try {
      final updated = await apiClient.updateProfile(token: token, update: update);
      // full_name lives on the User row, not Profile -- keep the session's
      // cached user in sync so the rest of the app (greeting, etc.) reflects it.
      await session.refreshUser();
      if (!mounted) return;
      Navigator.pop(context, updated);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await session.forceSignOut();
        return;
      }
      setState(() => _formError = e.message);
    } catch (e) {
      setState(() => _formError = "Couldn't reach the server. Check your connection and try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (_formError != null) ...[
                InfoBanner(
                  message: _formError!,
                  icon: Icons.error_outline_rounded,
                  accent: AppColors.error,
                  background: AppColors.errorSurface,
                ),
                AppSpacing.gapMd,
              ],
              AppTextField(
                controller: _nameController,
                label: 'Full name',
                prefixIcon: Icons.person_outline_rounded,
                validator: AuthValidators.fullName,
              ),
              AppSpacing.gapXl,
              const _SectionHeader(title: 'Education', icon: Icons.school_outlined),
              ..._educationDrafts.asMap().entries.map(
                    (entry) => _EducationEditor(
                      key: ValueKey(entry.value),
                      draft: entry.value,
                      onRemove: () => setState(() {
                        entry.value.dispose();
                        _educationDrafts.removeAt(entry.key);
                      }),
                    ),
                  ),
              if (_educationDrafts.length < _kMaxListItems)
                _AddRowButton(
                  label: 'Add education',
                  onTap: () => setState(() => _educationDrafts.add(_EducationDraft())),
                ),
              AppSpacing.gapXl,
              const _SectionHeader(title: 'Skills', icon: Icons.star_outline_rounded),
              _ChipInputRow(
                controller: _skillInputController,
                hint: 'e.g. Python',
                onAdd: () => _addSkill(() {
                  final v = _skillInputController.text;
                  _skillInputController.clear();
                  return v;
                }, _skills),
              ),
              if (_skills.isNotEmpty) ...[
                AppSpacing.gapSm,
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: _skills
                      .map((s) => InputChip(
                            label: Text(s),
                            onDeleted: () => setState(() => _skills.remove(s)),
                          ))
                      .toList(growable: false),
                ),
              ],
              AppSpacing.gapXl,
              const _SectionHeader(title: 'Experience', icon: Icons.work_outline_rounded),
              ..._experienceDrafts.asMap().entries.map(
                    (entry) => _ExperienceEditor(
                      key: ValueKey(entry.value),
                      draft: entry.value,
                      onRemove: () => setState(() {
                        entry.value.dispose();
                        _experienceDrafts.removeAt(entry.key);
                      }),
                    ),
                  ),
              if (_experienceDrafts.length < _kMaxListItems)
                _AddRowButton(
                  label: 'Add experience',
                  onTap: () => setState(() => _experienceDrafts.add(_ExperienceDraft())),
                ),
              AppSpacing.gapXl,
              const _SectionHeader(title: 'Career interests', icon: Icons.explore_outlined),
              _ChipInputRow(
                controller: _interestInputController,
                hint: 'e.g. Product Management',
                onAdd: () => _addSkill(() {
                  final v = _interestInputController.text;
                  _interestInputController.clear();
                  return v;
                }, _careerInterests),
              ),
              if (_careerInterests.isNotEmpty) ...[
                AppSpacing.gapSm,
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: _careerInterests
                      .map((s) => InputChip(
                            label: Text(s),
                            onDeleted: () => setState(() => _careerInterests.remove(s)),
                          ))
                      .toList(growable: false),
                ),
              ],
              AppSpacing.gapXl,
              PrimaryButton(label: 'Save profile', loadingLabel: 'Saving…', onPressed: _save),
              AppSpacing.gapLg,
            ],
          ),
        ),
      ),
    );
  }
}

// --- Drafts (hold their own controllers; disposed by the parent) -----------

class _EducationDraft {
  final TextEditingController school;
  final TextEditingController degree;
  final TextEditingController fieldOfStudy;
  final TextEditingController startYear;
  final TextEditingController endYear;

  _EducationDraft({EducationItem? from})
      : school = TextEditingController(text: from?.school ?? ''),
        degree = TextEditingController(text: from?.degree ?? ''),
        fieldOfStudy = TextEditingController(text: from?.fieldOfStudy ?? ''),
        startYear = TextEditingController(text: from?.startYear?.toString() ?? ''),
        endYear = TextEditingController(text: from?.endYear?.toString() ?? '');

  bool get isBlank => school.text.trim().isEmpty && degree.text.trim().isEmpty;

  void dispose() {
    school.dispose();
    degree.dispose();
    fieldOfStudy.dispose();
    startYear.dispose();
    endYear.dispose();
  }

  EducationItem? toItemOrNull() {
    if (isBlank) return null;
    return EducationItem(
      school: school.text.trim(),
      degree: degree.text.trim(),
      fieldOfStudy: fieldOfStudy.text.trim().isEmpty ? null : fieldOfStudy.text.trim(),
      startYear: int.tryParse(startYear.text.trim()),
      endYear: int.tryParse(endYear.text.trim()),
    );
  }
}

class _ExperienceDraft {
  final TextEditingController title;
  final TextEditingController company;
  final TextEditingController startDate;
  final TextEditingController endDate;
  final TextEditingController description;
  bool currentlyWorking;

  _ExperienceDraft({ExperienceItem? from})
      : title = TextEditingController(text: from?.title ?? ''),
        company = TextEditingController(text: from?.company ?? ''),
        startDate = TextEditingController(text: from?.startDate ?? ''),
        endDate = TextEditingController(text: from?.endDate ?? ''),
        description = TextEditingController(text: from?.description ?? ''),
        currentlyWorking = from?.currentlyWorking ?? false;

  bool get isBlank => title.text.trim().isEmpty && company.text.trim().isEmpty;

  void dispose() {
    title.dispose();
    company.dispose();
    startDate.dispose();
    endDate.dispose();
    description.dispose();
  }

  ExperienceItem? toItemOrNull() {
    if (isBlank) return null;
    return ExperienceItem(
      title: title.text.trim(),
      company: company.text.trim(),
      startDate: startDate.text.trim().isEmpty ? null : startDate.text.trim(),
      endDate: currentlyWorking || endDate.text.trim().isEmpty ? null : endDate.text.trim(),
      currentlyWorking: currentlyWorking,
      description: description.text.trim().isEmpty ? null : description.text.trim(),
    );
  }
}

// --- Small building blocks ---------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          AppSpacing.wGapSm,
          Text(title, style: context.text.titleMedium),
        ],
      ),
    );
  }
}

class _AddRowButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddRowButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SecondaryButton(label: label, icon: Icons.add_rounded, onPressed: onTap, expand: false),
    );
  }
}

class _ChipInputRow extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onAdd;

  const _ChipInputRow({required this.controller, required this.hint, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: controller,
            label: 'Add',
            hint: hint,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onAdd(),
          ),
        ),
        AppSpacing.wGapSm,
        IconButton.filled(onPressed: onAdd, icon: const Icon(Icons.add_rounded)),
      ],
    );
  }
}

class _EducationEditor extends StatelessWidget {
  final _EducationDraft draft;
  final VoidCallback onRemove;

  const _EducationEditor({super.key, required this.draft, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Education', style: context.text.labelLarge)),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  tooltip: 'Remove',
                  onPressed: onRemove,
                ),
              ],
            ),
            AppTextField(
              controller: draft.school,
              label: 'School',
              validator: (_) => _requiredTogetherValidator(draft.school.text, draft.degree.text),
            ),
            AppSpacing.gapSm,
            AppTextField(
              controller: draft.degree,
              label: 'Degree',
              validator: (_) => _requiredTogetherValidator(draft.degree.text, draft.school.text),
            ),
            AppSpacing.gapSm,
            AppTextField(controller: draft.fieldOfStudy, label: 'Field of study (optional)'),
            AppSpacing.gapSm,
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: draft.startYear,
                    label: 'Start year',
                    keyboardType: TextInputType.number,
                    validator: _yearValidator,
                  ),
                ),
                AppSpacing.wGapSm,
                Expanded(
                  child: AppTextField(
                    controller: draft.endYear,
                    label: 'End year',
                    keyboardType: TextInputType.number,
                    validator: _yearValidator,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperienceEditor extends StatefulWidget {
  final _ExperienceDraft draft;
  final VoidCallback onRemove;

  const _ExperienceEditor({super.key, required this.draft, required this.onRemove});

  @override
  State<_ExperienceEditor> createState() => _ExperienceEditorState();
}

class _ExperienceEditorState extends State<_ExperienceEditor> {
  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Experience', style: context.text.labelLarge)),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  tooltip: 'Remove',
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            AppTextField(
              controller: draft.title,
              label: 'Job title',
              validator: (_) => _requiredTogetherValidator(draft.title.text, draft.company.text),
            ),
            AppSpacing.gapSm,
            AppTextField(
              controller: draft.company,
              label: 'Company',
              validator: (_) => _requiredTogetherValidator(draft.company.text, draft.title.text),
            ),
            AppSpacing.gapSm,
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: draft.startDate,
                    label: 'Start (e.g. 2022-06)',
                  ),
                ),
                AppSpacing.wGapSm,
                Expanded(
                  child: AppTextField(
                    controller: draft.endDate,
                    label: 'End',
                    enabled: !draft.currentlyWorking,
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              value: draft.currentlyWorking,
              onChanged: (v) => setState(() => draft.currentlyWorking = v ?? false),
              title: const Text('I currently work here'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            AppTextField(controller: draft.description, label: 'Description (optional)', maxLines: 3),
          ],
        ),
      ),
    );
  }
}

/// Both fields in a pair (school/degree, title/company) are required
/// together once either has content -- mirrors the backend's EducationItem
/// / ExperienceItem, which require both. An entirely blank row is allowed
/// (it's simply dropped, see _EducationDraft/_ExperienceDraft.toItemOrNull).
String? _requiredTogetherValidator(String thisField, String otherField) {
  if (thisField.trim().isEmpty && otherField.trim().isNotEmpty) {
    return 'Required';
  }
  return null;
}

String? _yearValidator(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return null;
  final year = int.tryParse(v);
  if (year == null) return 'Enter a valid year';
  if (year < 1900 || year > DateTime.now().year + 10) return 'Enter a valid year';
  return null;
}
