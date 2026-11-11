import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/alert_service.dart';
import '../theme/app_colors.dart';

/// Selección de imagen para el formulario de producto.
class ProductImageSelection {
  final File? file;
  final String url;
  final bool useUrl;

  const ProductImageSelection({
    this.file,
    this.url = '',
    this.useUrl = true,
  });

  String? get value {
    if (useUrl) {
      final trimmed = url.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return file?.path;
  }
}

enum _ImageSource { url, file }

/// Selector de imagen con previsualización, pestaña URL/Archivo y validación.
class ProductImagePicker extends StatefulWidget {
  final ValueChanged<ProductImageSelection> onChanged;

  const ProductImagePicker({
    super.key,
    required this.onChanged,
  });

  @override
  State<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  final _imagePicker = ImagePicker();
  final _urlCtrl = TextEditingController();
  final _urlFocus = FocusNode();

  Timer? _urlDebounce;
  _ImageSource _source = _ImageSource.url;
  File? _selectedImage;
  String _previewUrl = '';

  @override
  void dispose() {
    _urlDebounce?.cancel();
    _urlCtrl.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(
      ProductImageSelection(
        file: _selectedImage,
        url: _urlCtrl.text,
        useUrl: _source == _ImageSource.url,
      ),
    );
  }

  void _handleUrlChanged(String value) {
    _urlDebounce?.cancel();
    _urlDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _previewUrl = value.trim());
    });
    _notify();
  }

  void _handleSourceChanged(Set<_ImageSource> selection) {
    if (selection.isEmpty) return;
    final source = selection.first;

    setState(() {
      _source = source;
      if (source == _ImageSource.url) {
        _previewUrl = _urlCtrl.text.trim();
      } else {
        _urlFocus.unfocus();
      }
    });
    _notify();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null || !mounted) return;

      setState(() {
        _selectedImage = File(image.path);
        _source = _ImageSource.file;
      });
      _notify();
    } catch (_) {
      if (mounted) {
        AlertService.instance.error(
          'No se pudo seleccionar la imagen. Intenta de nuevo.',
          context: context,
        );
      }
    }
  }

  void _clearUrl() {
    _urlDebounce?.cancel();
    _urlCtrl.clear();
    setState(() => _previewUrl = '');
    _notify();
  }

  void _clearFile() {
    setState(() => _selectedImage = null);
    _notify();
  }

  Widget _buildPreview() {
    if (_source == _ImageSource.url && _previewUrl.isNotEmpty) {
      return Image.network(
        _previewUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const _PreviewPlaceholder(
            icon: Icons.hourglass_empty_rounded,
            title: 'Cargando imagen...',
          );
        },
        errorBuilder: (_, _, _) => const _PreviewPlaceholder(
          icon: Icons.broken_image_outlined,
          title: 'No se pudo cargar la imagen',
          subtitle: 'Verifica que la URL sea pública y válida.',
        ),
      );
    }

    if (_source == _ImageSource.file && _selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const _PreviewPlaceholder(
          icon: Icons.broken_image_outlined,
          title: 'No se pudo cargar el archivo',
          subtitle: 'Selecciona otra imagen.',
        ),
      );
    }

    return _PreviewPlaceholder(
      icon: _source == _ImageSource.url ? Icons.link_rounded : Icons.cloud_upload_outlined,
      title: _source == _ImageSource.url
          ? 'Vista previa de la imagen'
          : 'Toca para seleccionar una imagen',
      subtitle: _source == _ImageSource.url
          ? 'Pega una URL pública para verla aquí.'
          : 'Elige un archivo JPG, PNG o WEBP desde tu dispositivo.',
    );
  }

  Widget _buildSourceToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SegmentedButton<_ImageSource>(
        segments: const [
          ButtonSegment<_ImageSource>(
            value: _ImageSource.url,
            label: Text('URL'),
            icon: Icon(Icons.link_rounded, size: 16),
          ),
          ButtonSegment<_ImageSource>(
            value: _ImageSource.file,
            label: Text('Archivo'),
            icon: Icon(Icons.upload_file_rounded, size: 16),
          ),
        ],
        selected: {_source},
        onSelectionChanged: _handleSourceChanged,
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.textPrimary;
          }),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.fieldBorder)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildFileInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.upload_file_rounded, size: 18),
          label: Text(_selectedImage == null ? 'Seleccionar archivo' : 'Cambiar archivo'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.fieldBorder),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedImage != null)
          Row(
            children: [
              const Icon(Icons.image_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _selectedImage!.path.split(RegExp(r'[/\\]')).last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: _clearFile,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorDark,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Quitar'),
              ),
            ],
          )
        else
          const Text(
            'Formatos: JPG, PNG o WEBP. Tamaño recomendado: 1200 × 800 px.',
            style: TextStyle(fontSize: 11.5, height: 1.4, color: AppColors.textSecondary),
          ),
      ],
    );
  }

  Widget _buildUrlField() {
    return TextFormField(
      controller: _urlCtrl,
      focusNode: _urlFocus,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      onChanged: _handleUrlChanged,
      autovalidateMode: AutovalidateMode.disabled,
      validator: _validateUrl,
      decoration: InputDecoration(
        labelText: 'URL de la imagen',
        hintText: 'https://ejemplo.com/producto.jpg',
        helperText: 'Usa una URL pública (http o https).',
        helperMaxLines: 2,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        helperStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.3),
        errorStyle: const TextStyle(color: AppColors.errorDark, fontSize: 11.5, fontWeight: FontWeight.w500),
        prefixIcon: const Icon(Icons.link_rounded, size: 20, color: AppColors.textSecondary),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _urlCtrl,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              onPressed: _clearUrl,
              tooltip: 'Quitar URL',
              icon: const Icon(Icons.close_rounded, size: 18),
            );
          },
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }

  String? _validateUrl(String? value) {
    if (_source != _ImageSource.url) return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > 500) {
      return 'La URL no puede superar 500 caracteres';
    }
    final uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) {
      return 'Ingresa una URL válida que empiece por http:// o https://';
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return 'Ingresa una URL válida que empiece por http:// o https://';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPreview(),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.24),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _buildSourceToggle(),
                      ),
                    ),
                    if (_source == _ImageSource.file && _selectedImage != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          color: AppColors.surface.withValues(alpha: 0.94),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: _clearFile,
                            tooltip: 'Quitar imagen',
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textPrimary),
                            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: _source == _ImageSource.url ? _buildUrlField() : _buildFileInput(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _PreviewPlaceholder({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fieldFill,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: AppColors.primary.withValues(alpha: 0.65)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
