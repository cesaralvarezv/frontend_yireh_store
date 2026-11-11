import 'package:flutter/material.dart';
import '../../controllers/category_controller.dart';
import '../../models/category_model.dart';
import '../../services/alert_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';

/// Formulario para crear/editar categoría — solo ADMIN.
class CreateCategoryView extends StatefulWidget {
  final CategoryModel? category; // null = crear, not null = editar

  const CreateCategoryView({super.key, this.category});

  @override
  State<CreateCategoryView> createState() => _CreateCategoryViewState();
}

class _CreateCategoryViewState extends State<CreateCategoryView> {
  final _formKey = GlobalKey<FormState>();
  late final CategoryController _categoryCtrl;
  final _alerts = AlertService.instance;

  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _iconCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _orderCtrl = TextEditingController();
  String _selectedLocation = 'Piso 3';

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _categoryCtrl = CategoryController();
    _categoryCtrl.addListener(_onChanged);
    _isEditing = widget.category != null;

    if (_isEditing) {
      final cat = widget.category!;
      _nameCtrl.text = cat.name;
      _descriptionCtrl.text = cat.description;
      _iconCtrl.text = cat.icon;
      _imageUrlCtrl.text = cat.imageUrl;
      _selectedLocation = cat.location.isNotEmpty ? cat.location : 'Piso 3';
      _orderCtrl.text = cat.order.toString();
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _categoryCtrl.removeListener(_onChanged);
    _categoryCtrl.dispose();
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _iconCtrl.dispose();
    _imageUrlCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final icon = _iconCtrl.text.trim();
    final imageUrl = _imageUrlCtrl.text.trim();
    final order = int.tryParse(_orderCtrl.text.trim()) ?? 0;

    bool success;
    if (_isEditing) {
      success = await _categoryCtrl.updateCategory(
        id: widget.category!.id,
        name: name,
        description: description,
        icon: icon,
        imageUrl: imageUrl,
        location: _selectedLocation,
        order: order,
      );
    } else {
      success = await _categoryCtrl.createCategory(
        name: name,
        description: description,
        icon: icon,
        imageUrl: imageUrl,
        location: _selectedLocation,
        order: order,
      );
    }

    if (!mounted) return;

    if (success) {
      _alerts.success(_categoryCtrl.successMessage ?? (_isEditing ? 'Categoría actualizada' : 'Categoría creada'), context: context);
      Navigator.of(context).pop(true);
    } else {
      _alerts.error(_categoryCtrl.errorMessage ?? 'Error', context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    _alerts.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(_isEditing ? 'Editar categoría' : 'Nueva categoría', style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre
              _buildField(
                label: 'Nombre *',
                child: TextFormField(
                  controller: _nameCtrl,
                  validator: Validators.name,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Ej: Bebidas, Comidas, Postres'),
                ),
              ),
              const SizedBox(height: 14),

              // Descripción
              _buildField(
                label: 'Descripción',
                child: TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Descripción opcional de la categoría'),
                ),
              ),
              const SizedBox(height: 14),

              // Icono
              _buildField(
                label: 'Icono (emoji) *',
                child: TextFormField(
                  controller: _iconCtrl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Icono requerido (emoji)';
                    if (v.trim().length > 4) return 'Máximo 4 caracteres (emoji)';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Ej: ☕, 🍔, 🍰').copyWith(
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.emoji_emotions_rounded, color: AppColors.textHint, size: 20),
                      onPressed: _showEmojiPicker,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Imagen (URL)
              _buildField(
                label: 'Imagen (URL)',
                child: TextFormField(
                  controller: _imageUrlCtrl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: _inputDecoration('https://images.unsplash.com/...').copyWith(
                    helperText: 'Usa una imagen libre de derechos (Unsplash o Pexels)',
                    helperMaxLines: 2,
                  ),
                ),
              ),
              if (_imageUrlCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imageUrlCtrl.text.trim(),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 80,
                      alignment: Alignment.center,
                      color: AppColors.fieldFill,
                      child: const Text(
                        'No se pudo cargar la vista previa',
                        style: TextStyle(fontSize: 12, color: AppColors.textHint),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Ubicación
              _buildField(
                label: 'Ubicación *',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLocation,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Piso 3', child: Text('Piso 3')),
                        DropdownMenuItem(value: 'Primer Piso', child: Text('Primer Piso')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLocation = value);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Orden
              _buildField(
                label: 'Orden *',
                child: TextFormField(
                  controller: _orderCtrl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Orden requerido';
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 0) return 'Número entero >= 0';
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSubmit(),
                  decoration: _inputDecoration('Ej: 0, 1, 2...'),
                ),
              ),
              const SizedBox(height: 8),

              if (_isEditing)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.infoSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cambios se aplicarán inmediatamente',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),

              // Botón crear/actualizar
              GestureDetector(
                onTap: _categoryCtrl.isLoading ? null : _handleSubmit,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _categoryCtrl.isLoading ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _categoryCtrl.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isEditing ? 'Actualizar categoría' : 'Crear categoría',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    final emojis = ['☕', '🍵', '🍔', '🍟', '🍕', '🌮', '🍰', '🍪', '🍩', '🍦', '🥤', '🍻', '🥗', '🥪', '🍣', '🍜'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Seleccionar icono', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emojis.map((e) => GestureDetector(
                onTap: () {
                  _iconCtrl.text = e;
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}