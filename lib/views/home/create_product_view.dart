import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/category_model.dart';
import '../../services/alert_service.dart';
import '../../services/product_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/category_formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/product_image_picker.dart';

/// Formulario para crear un producto — solo ADMIN.
class CreateProductView extends StatefulWidget {
  final CategoryModel category;

  const CreateProductView({
    super.key,
    required this.category,
  });

  @override
  State<CreateProductView> createState() => _CreateProductViewState();
}

class _CreateProductViewState extends State<CreateProductView> {
  final _formKey = GlobalKey<FormState>();
  final _alerts = AlertService.instance;
  final _productService = ProductService();

  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _orderCtrl = TextEditingController();
  final _advancedController = ExpansibleController();

  ProductImageSelection _imageSelection = const ProductImageSelection();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descriptionCtrl.dispose();
    _orderCtrl.dispose();
    _advancedController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final required = Validators.name(value);
    if (required != null) return required;
    if (value!.trim().length > 100) return 'Máximo 100 caracteres';
    return null;
  }

  String? _validatePrice(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa un precio mayor a 0';
    final normalized = text.replaceAll(',', '.');
    final number = double.tryParse(normalized);
    if (number == null || number <= 0) return 'Ingresa un precio mayor a 0';
    if (number > 99999999.99) return 'El precio es demasiado alto';
    return null;
  }

  String? _validateDescription(String? value) {
    if (value != null && value.trim().length > 500) {
      return 'Máximo 500 caracteres';
    }
    return null;
  }

  String? _validateOrder(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final number = int.tryParse(text);
    if (number == null || number < 0) return 'Ingresa un número entero mayor o igual a 0';
    return null;
  }

  double _parsePrice(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  int _parseOrder(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0;
    return int.tryParse(trimmed) ?? 0;
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      if (_validateOrder(_orderCtrl.text) != null) {
        _advancedController.expand();
      }
      return;
    }

    setState(() => _isLoading = true);

    final name = _nameCtrl.text.trim();
    final price = _parsePrice(_priceCtrl.text);
    final description = _descriptionCtrl.text.trim();
    final order = _parseOrder(_orderCtrl.text);
    final imageUrl = _imageSelection.value;

    try {
      await _productService.createProduct(
        name: name,
        price: price,
        description: description.isNotEmpty ? description : null,
        imageUrl: imageUrl,
        categoryId: int.parse(widget.category.id),
        order: order,
      );

      if (!mounted) return;
      _alerts.success('Producto "$name" creado exitosamente', context: context);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      _alerts.error(message, context: context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    String? helper,
    IconData? prefixIcon,
    String? prefixText,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 2,
      alignLabelWithHint: alignLabelWithHint,
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
      helperStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11.5,
        height: 1.3,
      ),
      errorStyle: const TextStyle(
        color: AppColors.errorDark,
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 20, color: AppColors.textSecondary),
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: AppColors.fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    _alerts.init(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _ProductFormAppBar(
        categoryName: formatCategoryTitle(widget.category.name),
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionCard(
                title: 'Imagen del producto',
                subtitle: 'Agrega una URL o sube un archivo desde tu dispositivo.',
                child: ProductImagePicker(
                  onChanged: (selection) {
                    setState(() => _imageSelection = selection);
                  },
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Información básica',
                subtitle: 'Completa los datos principales del producto.',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      validator: _validateName,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: _fieldDecoration(
                        label: 'Nombre del producto',
                        hint: 'Ej. Café americano',
                        helper: 'Máximo 100 caracteres.',
                        prefixIcon: Icons.local_cafe_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceCtrl,
                      validator: _validatePrice,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: _fieldDecoration(
                        label: 'Precio (COP)',
                        hint: 'Ej. 12000',
                        helper: 'Usa números. Ej. 12000 o 12000.50.',
                        prefixText: '\$ ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionCtrl,
                      validator: _validateDescription,
                      minLines: 3,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _fieldDecoration(
                        label: 'Descripción',
                        hint: 'Ingredientes, tamaño o detalles del producto.',
                        helper: 'Opcional. Máximo 500 caracteres.',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AdvancedOptionsCard(
                controller: _advancedController,
                child: TextFormField(
                  controller: _orderCtrl,
                  validator: _validateOrder,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onFieldSubmitted: (_) => _handleSubmit(),
                  decoration: _fieldDecoration(
                    label: 'Orden de visualización',
                    hint: 'Automático (0)',
                    helper: 'Opcional. Si lo dejas vacío, se usará 0.',
                    prefixIcon: Icons.sort_rounded,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _SubmitBar(
        isLoading: _isLoading,
        onPressed: _handleSubmit,
      ),
    );
  }
}

class _ProductFormAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String categoryName;
  final VoidCallback onBack;

  const _ProductFormAppBar({
    required this.categoryName,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 72,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 4,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AppBackButton(
            onPressed: onBack,
            tooltip: 'Volver',
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Nuevo producto',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.category_outlined, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Categoría · $categoryName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AdvancedOptionsCard extends StatelessWidget {
  final ExpansibleController controller;
  final Widget child;

  const _AdvancedOptionsCard({
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          controller: controller,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune_rounded, size: 20, color: AppColors.primary),
          ),
          title: const Text(
            'Opciones avanzadas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: const Text(
            'Configura el orden de visualización',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          children: [child],
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitBar({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Crear producto',
                      key: ValueKey('label'),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
