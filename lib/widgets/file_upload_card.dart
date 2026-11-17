import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_theme.dart';

/// Upload card for a single PDF/DOCX file (resume or job description).
/// Mirrors the original Streamlit `st.file_uploader(type=["pdf","docx"])`
/// behavior and the backend's 10MB hard cap (app.core.config).
class FileUploadCard extends StatefulWidget {
  final String label;
  final String hint;
  final ValueChanged<PickedFile?> onChanged;

  const FileUploadCard({super.key, required this.label, this.hint = 'PDF or DOCX', required this.onChanged});

  @override
  State<FileUploadCard> createState() => _FileUploadCardState();
}

class _FileUploadCardState extends State<FileUploadCard> {
  PickedFile? _picked;
  String? _error;

  static const _maxBytes = 10 * 1024 * 1024; // matches backend MAX_UPLOAD_SIZE_BYTES

  Future<void> _pickFile() async {
    setState(() => _error = null);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: true, // ensures bytes are populated on every platform, incl. web
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.bytes == null) {
      setState(() => _error = "Couldn't read that file. Please try again.");
      return;
    }
    if (file.bytes!.length > _maxBytes) {
      setState(() => _error = 'File is too large (max 10MB).');
      return;
    }

    final picked = PickedFile(
      filename: file.name,
      bytes: file.bytes!,
      contentType: file.extension == 'pdf'
          ? 'application/pdf'
          : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
    setState(() => _picked = picked);
    widget.onChanged(picked);
  }

  void _clear() {
    setState(() => _picked = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _picked == null ? _pickFile : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _picked != null ? Icons.description : Icons.upload_file,
                color: _picked != null ? AppTheme.success : AppTheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      _picked?.filename ?? widget.hint,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              if (_picked != null)
                IconButton(icon: const Icon(Icons.close), onPressed: _clear)
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
