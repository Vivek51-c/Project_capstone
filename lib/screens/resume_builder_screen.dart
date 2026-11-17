import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../core/app_colors.dart';
import '../core/auth/session_controller.dart';
import '../core/local_history.dart';
import '../core/resume_download.dart';
import '../main.dart';
import '../models/resume_builder_models.dart';
import '../widgets/common_widgets.dart';

class ResumeBuilderScreen extends StatefulWidget {
  final ResumeBuilderFormState? initialForm;

  const ResumeBuilderScreen({super.key, this.initialForm});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  late final ResumeBuilderFormState _form;
  int _currentStep = 0;

  // Step 0: Resume Type, Step 1-9: form sections
  static const _stepCount = 10;

  @override
  void initState() {
    super.initState();
    _form = widget.initialForm ?? ResumeBuilderFormState();
  }

  void _next() {
    if (_currentStep < _stepCount - 1) {
      setState(() => _currentStep += 1);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Resume Builder')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _next,
        onStepCancel: _back,
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              if (_currentStep < _stepCount - 1)
                ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Next')),
              if (_currentStep > 0) ...[
                const SizedBox(width: 12),
                OutlinedButton(
                    onPressed: details.onStepCancel, child: const Text('Back')),
              ],
            ],
          ),
        ),
        steps: [
          Step(
            title: const Text('Resume Type'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _ResumeTypeStep(form: _form),
          ),
          Step(
            title: const Text('Personal Details'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _PersonalInfoStep(form: _form),
          ),
          Step(
            title: const Text('Professional Summary'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: _SummaryStep(form: _form),
          ),
          Step(
            title: const Text('Education'),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            content: _EducationStep(form: _form),
          ),
          Step(
            title: const Text('Work Experience'),
            isActive: _currentStep >= 4,
            state: _currentStep > 4 ? StepState.complete : StepState.indexed,
            content: _ExperienceStep(form: _form),
          ),
          Step(
            title: const Text('Projects'),
            isActive: _currentStep >= 5,
            state: _currentStep > 5 ? StepState.complete : StepState.indexed,
            content: _ProjectsStep(form: _form),
          ),
          Step(
            title: const Text('Skills'),
            isActive: _currentStep >= 6,
            state: _currentStep > 6 ? StepState.complete : StepState.indexed,
            content: _SkillsStep(form: _form),
          ),
          Step(
            title: const Text('Certifications & Training'),
            isActive: _currentStep >= 7,
            state: _currentStep > 7 ? StepState.complete : StepState.indexed,
            content: _CertificationsStep(form: _form),
          ),
          Step(
            title: const Text('Achievements & Interests'),
            isActive: _currentStep >= 8,
            state: _currentStep > 8 ? StepState.complete : StepState.indexed,
            content: _ExtrasStep(form: _form),
          ),
          Step(
            title: const Text('Review & Generate'),
            isActive: _currentStep >= 9,
            state: StepState.indexed,
            content: _ReviewStep(form: _form),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Step 0: Resume Type (Fresher / Experienced)
// ---------------------------------------------------------------------

class _ResumeTypeStep extends StatefulWidget {
  final ResumeBuilderFormState form;
  const _ResumeTypeStep({required this.form});

  @override
  State<_ResumeTypeStep> createState() => _ResumeTypeStepState();
}

class _ResumeTypeStepState extends State<_ResumeTypeStep> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select your profile type',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 6),
        const Text(
          'This helps tailor the resume to what recruiters expect for your experience level.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ...ResumeType.values.map((type) {
          final selected = widget.form.resumeType == type;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => widget.form.resumeType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.4),
                    width: selected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: selected
                      ? colorScheme.primary.withValues(alpha: 0.06)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      type == ResumeType.fresher
                          ? Icons.school_outlined
                          : Icons.work_outline,
                      color: selected ? colorScheme.primary : Colors.grey,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selected ? colorScheme.primary : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            type == ResumeType.fresher
                                ? 'No or limited work experience — student or recent graduate'
                                : 'Has professional work experience',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle,
                          color: colorScheme.primary, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Step 1: Personal Info
// ---------------------------------------------------------------------

class _PersonalInfoStep extends StatefulWidget {
  final ResumeBuilderFormState form;
  const _PersonalInfoStep({required this.form});

  @override
  State<_PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<_PersonalInfoStep> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final p = widget.form.personal;
    _controllers = {
      'name': TextEditingController(text: p.name),
      'email': TextEditingController(text: p.email),
      'phone': TextEditingController(text: p.phone),
      'title': TextEditingController(text: p.title),
      'location': TextEditingController(text: p.location),
      'linkedin': TextEditingController(text: p.linkedin),
      'github': TextEditingController(text: p.github),
      'website': TextEditingController(text: p.website),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(String key, String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controllers[key],
        decoration: InputDecoration(labelText: required ? '$label *' : label),
        onChanged: (v) {
          final p = widget.form.personal;
          switch (key) {
            case 'name':
              p.name = v;
              break;
            case 'email':
              p.email = v;
              break;
            case 'phone':
              p.phone = v;
              break;
            case 'title':
              p.title = v;
              break;
            case 'location':
              p.location = v;
              break;
            case 'linkedin':
              p.linkedin = v;
              break;
            case 'github':
              p.github = v;
              break;
            case 'website':
              p.website = v;
              break;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _field('name', 'Full Name', required: true),
        _field('title', 'Target Job Title (e.g. Backend Engineer)'),
        _field('email', 'Email', required: true),
        _field('phone', 'Phone Number', required: true),
        _field('location', 'Location'),
        _field('linkedin', 'LinkedIn URL'),
        _field('github', 'GitHub URL'),
        _field('website', 'Personal Website URL'),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Step 2: Summary
// ---------------------------------------------------------------------

class _SummaryStep extends StatefulWidget {
  final ResumeBuilderFormState form;
  const _SummaryStep({required this.form});

  @override
  State<_SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends State<_SummaryStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.form.summary);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: 6,
      decoration: const InputDecoration(
        labelText: 'Professional Summary *',
        hintText: 'A few sentences on your experience and strengths…',
        alignLabelWithHint: true,
      ),
      onChanged: (v) => widget.form.summary = v,
    );
  }
}

// ---------------------------------------------------------------------
// Generic "add/remove entries" scaffold shared by Education/Experience/
// Projects/Certifications steps.
// ---------------------------------------------------------------------

class _RepeatingSection<T> extends StatefulWidget {
  final List<T> items;
  final T Function() createNew;
  final Widget Function(BuildContext context, T item, VoidCallback onChanged)
      itemBuilder;
  final String addLabel;

  const _RepeatingSection({
    required this.items,
    required this.createNew,
    required this.itemBuilder,
    required this.addLabel,
  });

  @override
  State<_RepeatingSection<T>> createState() => _RepeatingSectionState<T>();
}

class _RepeatingSectionState<T> extends State<_RepeatingSection<T>> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in widget.items)
          Card(
            key: ValueKey(item),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () =>
                          setState(() => widget.items.remove(item)),
                    ),
                  ),
                  widget.itemBuilder(context, item, () => setState(() {})),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(widget.addLabel),
          onPressed: () => setState(() => widget.items.add(widget.createNew())),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Step 4: Education
// ---------------------------------------------------------------------

/// Education entry editor — switches fields based on [EducationType].
class _EducationEntryEditor extends StatefulWidget {
  final EducationEntry entry;
  final VoidCallback onChanged;

  const _EducationEntryEditor(
      {required this.entry, required this.onChanged});

  @override
  State<_EducationEntryEditor> createState() => _EducationEntryEditorState();
}

class _EducationEntryEditorState extends State<_EducationEntryEditor> {
  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- type selector ----
        const Text(
          'Education Type',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: EducationType.values.map((type) {
              final selected = e.educationType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(type.label),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    e.educationType = type;
                    widget.onChanged();
                  }),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // ---- School / Class 10 / Class 12 fields ----
        if (e.educationType != EducationType.university) ...[
          _labeledField(
            'School / Institution Name *',
            e.schoolName,
            (v) { e.schoolName = v; widget.onChanged(); },
          ),
          LayoutBuilder(builder: (ctx, constraints) {
            final boardField = _labeledField(
              'Board (e.g. CBSE, ICSE, State Board)',
              e.board,
              (v) { e.board = v; widget.onChanged(); },
            );
            final yearField = _labeledField(
              'Passing Year',
              e.passingYear,
              (v) { e.passingYear = v; widget.onChanged(); },
            );
            if (constraints.maxWidth < 420) {
              return Column(children: [boardField, yearField]);
            }
            return Row(children: [
              Expanded(child: boardField),
              const SizedBox(width: 12),
              Expanded(child: yearField),
            ]);
          }),
          _labeledField(
            'Percentage / Marks',
            e.percentage,
            (v) { e.percentage = v; widget.onChanged(); },
          ),
        ],

        // ---- University / College fields ----
        if (e.educationType == EducationType.university) ...[
          _labeledField(
            'University / College Name *',
            e.university,
            (v) { e.university = v; widget.onChanged(); },
          ),
          _labeledField(
            'Degree (e.g. B.Tech, BCA, B.Sc) *',
            e.degree,
            (v) { e.degree = v; widget.onChanged(); },
          ),
          _labeledField(
            'Field of Study (e.g. Computer Science)',
            e.fieldOfStudy,
            (v) { e.fieldOfStudy = v; widget.onChanged(); },
          ),
          _labeledField(
            'Location (City)',
            e.location,
            (v) { e.location = v; widget.onChanged(); },
          ),
          LayoutBuilder(builder: (ctx, constraints) {
            final startDate = _labeledField(
              'Start Date (e.g. Aug 2020)',
              e.startDate,
              (v) { e.startDate = v; widget.onChanged(); },
            );
            final endDate = _labeledField(
              'End Date / Expected (e.g. May 2024)',
              e.endDate,
              (v) { e.endDate = v; widget.onChanged(); },
            );
            if (constraints.maxWidth < 420) {
              return Column(children: [startDate, endDate]);
            }
            return Row(children: [
              Expanded(child: startDate),
              const SizedBox(width: 12),
              Expanded(child: endDate),
            ]);
          }),
          LayoutBuilder(builder: (ctx, constraints) {
            final cgpaField = _labeledField(
              'CGPA (e.g. 8.5 / 10)',
              e.gpa,
              (v) { e.gpa = v; widget.onChanged(); },
            );
            final pctField = _labeledField(
              'Percentage (optional)',
              e.percentage,
              (v) { e.percentage = v; widget.onChanged(); },
            );
            if (constraints.maxWidth < 420) {
              return Column(children: [cgpaField, pctField]);
            }
            return Row(children: [
              Expanded(child: cgpaField),
              const SizedBox(width: 12),
              Expanded(child: pctField),
            ]);
          }),
          _labeledField(
            'Relevant Coursework (optional, comma-separated)',
            e.coursework,
            (v) { e.coursework = v; widget.onChanged(); },
            maxLines: 2,
          ),
        ],
      ],
    );
  }
}

class _EducationStep extends StatelessWidget {
  final ResumeBuilderFormState form;
  const _EducationStep({required this.form});

  @override
  Widget build(BuildContext context) {
    return _RepeatingSection<EducationEntry>(
      items: form.education,
      createNew: () => EducationEntry(),
      addLabel: 'Add Education',
      itemBuilder: (context, e, onChanged) =>
          _EducationEntryEditor(entry: e, onChanged: onChanged),
    );
  }
}

// ---------------------------------------------------------------------
// Step 5: Work Experience
// ---------------------------------------------------------------------

class _ExperienceStep extends StatelessWidget {
  final ResumeBuilderFormState form;
  const _ExperienceStep({required this.form});

  @override
  Widget build(BuildContext context) {
    final isFresher = form.resumeType == ResumeType.fresher;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isFresher) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'As a fresher, you can skip this section or add internships, part-time work, or freelance experience.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        _RepeatingSection<ExperienceEntry>(
          items: form.experience,
          createNew: () => ExperienceEntry(),
          addLabel:
              isFresher ? 'Add Internship / Part-time Work' : 'Add Work Experience',
          itemBuilder: (context, e, onChanged) => Column(
            children: [
              _labeledField('Job Title / Role *', e.jobTitle,
                  (v) => e.jobTitle = v),
              _labeledField('Company / Organisation *', e.company,
                  (v) => e.company = v),
              _labeledField('Location (City)', e.location,
                  (v) => e.location = v),
              LayoutBuilder(
                builder: (context, constraints) {
                  final startDate = _labeledField(
                      'Start Date (e.g. Jun 2023)', e.startDate,
                      (v) => e.startDate = v);
                  final endDate = _labeledField(
                      'End Date / Present', e.endDate,
                      (v) => e.endDate = v);
                  if (constraints.maxWidth < 420) {
                    return Column(children: [startDate, endDate]);
                  }
                  return Row(children: [
                    Expanded(child: startDate),
                    const SizedBox(width: 12),
                    Expanded(child: endDate),
                  ]);
                },
              ),
              _labeledField(
                'Key Responsibilities / Achievements (one per line)',
                e.responsibilities.join('\n'),
                (v) => e.responsibilities = v
                    .split('\n')
                    .map((l) => l.trim())
                    .where((l) => l.isNotEmpty)
                    .toList(),
                maxLines: 5,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Step 6: Projects
// ---------------------------------------------------------------------

class _ProjectsStep extends StatelessWidget {
  final ResumeBuilderFormState form;
  const _ProjectsStep({required this.form});

  @override
  Widget build(BuildContext context) {
    return _RepeatingSection<ProjectEntry>(
      items: form.projects,
      createNew: () => ProjectEntry(),
      addLabel: 'Add Project',
      itemBuilder: (context, e, onChanged) => Column(
        children: [
          _labeledField('Project Title *', e.title, (v) => e.title = v),
          _labeledField(
              'Tech Stack / Tools Used', e.techStack, (v) => e.techStack = v),
          _labeledField('GitHub / Source Code Link', e.link,
              (v) => e.link = v),
          _labeledField(
              'Live / Deployment URL (optional)', e.deployment,
              (v) => e.deployment = v),
          _labeledField(
              'Description — what it does, your role, impact (one point per line) *',
              e.description,
              (v) => e.description = v,
              maxLines: 4),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Step 7: Skills
// ---------------------------------------------------------------------

class _SkillsStep extends StatefulWidget {
  final ResumeBuilderFormState form;
  const _SkillsStep({required this.form});

  @override
  State<_SkillsStep> createState() => _SkillsStepState();
}

class _SkillsStepState extends State<_SkillsStep> {
  late final TextEditingController _techController;
  late final TextEditingController _softController;

  @override
  void initState() {
    super.initState();
    _techController =
        TextEditingController(text: widget.form.skills.technical.join(', '));
    _softController =
        TextEditingController(text: widget.form.skills.soft.join(', '));
  }

  @override
  void dispose() {
    _techController.dispose();
    _softController.dispose();
    super.dispose();
  }

  List<String> _parse(String v) =>
      v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _techController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Technical Skills *',
            hintText:
                'Python, SQL, AWS, Docker, React … (comma-separated)',
          ),
          onChanged: (v) => widget.form.skills.technical = _parse(v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _softController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Soft Skills',
            hintText: 'Communication, Leadership, Teamwork … (comma-separated)',
          ),
          onChanged: (v) => widget.form.skills.soft = _parse(v),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Step 8: Certifications & Training
// ---------------------------------------------------------------------

class _CertificationsStep extends StatelessWidget {
  final ResumeBuilderFormState form;
  const _CertificationsStep({required this.form});

  @override
  Widget build(BuildContext context) {
    return _RepeatingSection<CertificationEntry>(
      items: form.certifications,
      createNew: () => CertificationEntry(),
      addLabel: 'Add Certification or Training',
      itemBuilder: (context, e, onChanged) => Column(
        children: [
          _labeledField(
              'Certification / Course Title *', e.title, (v) => e.title = v),
          _labeledField(
              'Issuing Organisation (e.g. Coursera, Google, NASSCOM)',
              e.issuer,
              (v) => e.issuer = v),
          _labeledField(
              'Certificate URL (optional)', e.link, (v) => e.link = v),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Step 9: Achievements & Interests
// ---------------------------------------------------------------------

class _ExtrasStep extends StatefulWidget {
  final ResumeBuilderFormState form;
  const _ExtrasStep({required this.form});

  @override
  State<_ExtrasStep> createState() => _ExtrasStepState();
}

class _ExtrasStepState extends State<_ExtrasStep> {
  late final TextEditingController _achievementsController;
  late final TextEditingController _hobbiesController;

  @override
  void initState() {
    super.initState();
    _achievementsController =
        TextEditingController(text: widget.form.extras.achievements.join('\n'));
    _hobbiesController =
        TextEditingController(text: widget.form.extras.hobbies.join(', '));
  }

  @override
  void dispose() {
    _achievementsController.dispose();
    _hobbiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _achievementsController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Achievements / Awards / Extra-curriculars',
            hintText:
                'Won XYZ hackathon\nPublished paper on ABC\nDistrict-level cricket player',
            alignLabelWithHint: true,
          ),
          onChanged: (v) => widget.form.extras.achievements = v
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hobbiesController,
          decoration: const InputDecoration(
            labelText: 'Interests / Hobbies (comma-separated)',
            hintText: 'Reading, Open-source contribution, Chess',
          ),
          onChanged: (v) => widget.form.extras.hobbies = v
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Step 9: Review & Generate
// ---------------------------------------------------------------------

class _ReviewStep extends StatefulWidget {
  final ResumeBuilderFormState form;
  const _ReviewStep({required this.form});

  @override
  State<_ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends State<_ReviewStep> {
  ValidationResult? _validation;
  final _geminiKeyController = TextEditingController();
  final _newInformationController = TextEditingController();
  SavedResumeVersion? _savedResume;
  bool _loadingSavedResume = true;
  String? _savedResumeError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedResume());
  }

  @override
  void dispose() {
    _geminiKeyController.dispose();
    _newInformationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedResume() async {
    final token = SessionScope.of(context).token;
    if (token == null) {
      if (mounted) {
        setState(() => _loadingSavedResume = false);
      }
      return;
    }
    setState(() {
      _loadingSavedResume = true;
      _savedResumeError = null;
    });
    try {
      final saved = await apiClient.getLatestResume(token: token);
      if (!mounted) {
        return;
      }
      setState(() {
        _savedResume = saved;
        _loadingSavedResume = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _savedResumeError = e.toString();
        _loadingSavedResume = false;
      });
    }
  }

  Future<void> _saveDownload(Uint8List bytes, String filename) async {
    await LocalHistory.instance.recordResumeBuilt();
    final filePath = await saveResumeDownload(bytes, filename);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            filePath == null ? 'Downloading $filename' : 'Saved $filename'),
        action: filePath == null
            ? null
            : SnackBarAction(
                label: 'Open',
                onPressed: () => OpenFilex.open(filePath),
              ),
      ),
    );
  }

  Future<void> _validate() async {
    final result = await apiClient.validateResume(widget.form);
    setState(() => _validation = result);
  }

  Future<void> _generate() async {
    widget.form.geminiApiKey = _geminiKeyController.text.trim();
    final token = SessionScope.of(context).token;
    if (token == null) {
      throw StateError('Sign in to save your resume.');
    }
    final (bytes, filename) =
        await apiClient.generateResume(widget.form, token: token);
    await _saveDownload(bytes, filename);
    await _loadSavedResume();
  }

  Future<void> _updateResume() async {
    final information = _newInformationController.text.trim();
    if (information.isEmpty) {
      throw StateError('Enter the new skills or information to add.');
    }
    final token = SessionScope.of(context).token;
    if (token == null) {
      throw StateError('Sign in to update your resume.');
    }
    final (bytes, filename) = await apiClient.updateSavedResume(
      token: token,
      newInformation: information,
    );
    _newInformationController.clear();
    await _loadSavedResume();
    await _saveDownload(bytes, filename);
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('AI-Enhance with Gemini'),
          subtitle: const Text(
              'Polishes your summary, experience, projects & skills — without inventing facts'),
          value: form.aiEnhance,
          onChanged: (v) => setState(() => form.aiEnhance = v),
        ),
        if (form.aiEnhance) ...[
          DropdownButtonFormField<EnhancementTone>(
            initialValue: form.tone,
            decoration: const InputDecoration(labelText: 'Tone'),
            items: EnhancementTone.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.apiValue)))
                .toList(),
            onChanged: (v) =>
                setState(() => form.tone = v ?? EnhancementTone.professional),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _geminiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Gemini API Key',
              hintText: 'Leave blank to use the server default (if configured)',
            ),
          ),
        ],
        const SizedBox(height: 20),
        LoadingButton(
          label: 'Check for issues',
          icon: Icons.playlist_add_check,
          onPressed: () async {
            try {
              await _validate();
            } catch (e) {
              if (context.mounted) showErrorSnackBar(context, e);
            }
          },
        ),
        if (_validation != null) ...[
          const SizedBox(height: 16),
          if (_validation!.errors.isNotEmpty) ...[
            const Text('Please fix before generating:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            ..._validation!.errors
                .map((e) => FindingRow(isSuccess: false, message: e)),
          ],
          if (_validation!.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Recommended (optional):',
                style: TextStyle(fontWeight: FontWeight.w600)),
            ..._validation!.warnings
                .map((w) => FindingRow(isSuccess: false, message: w)),
          ],
          if (_validation!.isValid && _validation!.warnings.isEmpty)
            const FindingRow(
                isSuccess: true, message: 'Everything looks good!'),
        ],
        const SizedBox(height: 24),
        LoadingButton(
          label: 'Generate Resume (.docx)',
          icon: Icons.description,
          onPressed: () async {
            try {
              await _generate();
            } catch (e) {
              if (context.mounted) showErrorSnackBar(context, e);
            }
          },
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text('Update Saved Resume',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        const SizedBox(height: 6),
        const Text(
            'Add new skills or experience. Your current version will stay unchanged.'),
        const SizedBox(height: 12),
        if (_loadingSavedResume)
          const LinearProgressIndicator()
        else if (_savedResumeError != null) ...[
          Text('Could not load your saved resume: $_savedResumeError'),
          TextButton(
              onPressed: _loadSavedResume, child: const Text('Try again')),
        ] else if (_savedResume == null)
          const Text('Generate your first resume above to enable updates.')
        else ...[
          Text('Latest saved version: v${_savedResume!.version}'),
          const SizedBox(height: 8),
          TextField(
            controller: _newInformationController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'What is new?',
              hintText: 'I learned Python, FastAPI and Docker.',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          LoadingButton(
            label: 'Generate updated resume',
            icon: Icons.note_add_outlined,
            onPressed: () async {
              try {
                await _updateResume();
              } catch (e) {
                if (context.mounted) showErrorSnackBar(context, e);
              }
            },
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Shared small field helper for the repeating-section steps above.
// ---------------------------------------------------------------------

Widget _labeledField(
    String label, String initialValue, ValueChanged<String> onChanged,
    {int maxLines = 1}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    ),
  );
}
