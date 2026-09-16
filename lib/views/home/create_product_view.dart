import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/category_model.dart';
import '../../services/product_service.dart';
import '../../services/alert_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';

/// Formulario para crear producto — solo ADMIN.
class CreateProductView extends StatefulWidget {
  final CategoryModel category;

  const CreateProductView({super.key, required this.category});

  @override
  State<CreateProductView> createState() => _CreateProductViewState();
}

class _CreateProductViewState extends State<CreateProductView> {
  final _formKey = GlobalKey<FormState>();
  late final ProductService _productService;
  final _alerts = AlertService.instance;
  final _imagePicker = ImagePicker();

  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();

  bool _isLoading = false;
  bool _useUrl = true;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
    _quantityCtrl.text = '0';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descriptionCtrl.dispose();
    _imageUrlCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        _alerts.error('Error al seleccionar imagen: $e', context: context);
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageUrlCtrl.clear();
    });
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final description = _descriptionCtrl.text.trim();
    final quantity = int.tryParse(_quantityCtrl.text.trim()) ?? 0;

    String? imageUrl;
    if (_useUrl) {
      imageUrl = _imageUrlCtrl.text.trim();
      if (imageUrl.isEmpty) imageUrl = null;
    } else if (_selectedImage != null) {
      imageUrl = _selectedImage!.path;
    }

    try {
      await _productService.createProduct(
        name: name,
        price: price,
        description: description.isNotEmpty ? description : null,
        imageUrl: imageUrl,
        categoryId: int.parse(widget.category.id),
        order: quantity,
      );

      if (!mounted) return;
      _alerts.success('Producto "$name" creado exitosamente', context: context);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      _alerts.error(msg, context: context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Nuevo producto', style: TextStyle(fontWeight: FontWeight.w600)),
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
              // Categoría pre-seleccionada
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                      widget.category.icon.isNotEmpty ? widget.category.icon : '📦',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categoría',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          Text(
                            widget.category.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Selector de imagen
              _buildField(
                label: 'Imagen del producto',
                child: Column(
                  children: [
                    // Toggle entre URL y archivo
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.fieldBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _useUrl = true;
                                _selectedImage = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _useUrl ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.link,
                                      size: 16,
                                      color: _useUrl ? Colors.white : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'URL',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _useUrl ? Colors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _useUrl = false;
                                _imageUrlCtrl.clear();
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_useUrl ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder_open,
                                      size: 16,
                                      color: !_useUrl ? Colors.white : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Equipo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: !_useUrl ? Colors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Campo de URL o botón de archivo
                    if (_useUrl)
                      TextFormField(
                        controller: _imageUrlCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration('https://ejemplo.com/imagen.jpg'),
                      )
                    else
                      _buildFilePicker(),

                    // Preview de imagen
                    if ((!_useUrl && _selectedImage != null) || (_useUrl && _imageUrlCtrl.text.isNotEmpty))
                      _buildImagePreview(),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Nombre del producto
              _buildField(
                label: 'Nombre del producto *',
                child: TextFormField(
                  controller: _nameCtrl,
                  validator: Validators.name,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Ej: Café Americano, Sandwich...'),
                ),
              ),
              const SizedBox(height: 14),

              // Precio
              _buildField(
                label: 'Precio *',
                child: TextFormField(
                  controller: _priceCtrl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Precio requerido';
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Precio debe ser mayor a 0';
                    return null;
                  },
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Ej: 5000, 12000.50'),
                ),
              ),
              const SizedBox(height: 14),

              // Cantidad/Orden
              _buildField(
                label: 'Orden *',
                child: TextFormField(
                  controller: _quantityCtrl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Orden requerido';
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 0) return 'Número entero >= 0';
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Ej: 0, 1, 2...'),
                ),
              ),
              const SizedBox(height: 14),

              // Descripción
              _buildField(
                label: 'Descripción',
                child: TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSubmit(),
                  decoration: _inputDecoration('Descripción opcional del producto'),
                ),
              ),
              const SizedBox(height: 8),

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
                        'El producto se creará en la categoría "${widget.category.name}"',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Botón crear
              GestureDetector(
                onTap: _isLoading ? null : _handleSubmit,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isLoading ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Crear producto',
                            style: TextStyle(
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

  Widget _buildFilePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _selectedImage != null ? AppColors.primary : AppColors.fieldBorder,
            width: _selectedImage != null ? 1.5 : 1,
          ),
        ),
        child: _selectedImage == null
            ? Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.textHint),
                  const SizedBox(height: 8),
                  Text(
                    'Toca para seleccionar imagen',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Formatos: JPG, PNG, GIF',
                    style: TextStyle(fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              )
            : Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Imagen seleccionada',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedImage!.path.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: AppColors.error),
                    onPressed: _removeImage,
                    tooltip: 'Eliminar imagen',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _useUrl
            ? Image.network(
                _imageUrlCtrl.text,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'No se pudo cargar la imagen',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ),
                ),
              )
            : Image.file(
                _selectedImage!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
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
