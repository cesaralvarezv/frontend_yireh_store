import 'package:flutter/material.dart';
import '../../domain/port/out/wallet_repository_port.dart';
import '../../infrastructure/adapter/out/api_wallet_repository.dart';
import '../../models/wallet_model.dart';
import '../../theme/app_colors.dart';

class RecargasView extends StatefulWidget {
  final WalletRepositoryPort? walletRepository;

  const RecargasView({super.key, this.walletRepository});

  @override
  State<RecargasView> createState() => _RecargasViewState();
}

class _RecargasViewState extends State<RecargasView> {
  late final WalletRepositoryPort _walletRepo;
  final _customAmountCtrl = TextEditingController();

  double _balance = 0.0;
  bool _isLoadingBalance = true;
  bool _isProcessing = false;

  double _selectedAmount = 20000;
  String _selectedMethod = 'NEQUI';
  List<RechargeTransaction> _transactions = [];

  final List<double> _quickAmounts = [10000, 20000, 50000, 100000];

  @override
  void initState() {
    super.initState();
    _walletRepo = widget.walletRepository ?? ApiWalletRepository();
    _loadData();
  }

  @override
  void dispose() {
    _customAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingBalance = true;
    });
    try {
      final balance = await _walletRepo.getBalance();
      final txs = await _walletRepo.getTransactions();
      if (mounted) {
        setState(() {
          _balance = balance;
          _transactions = txs;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    }
  }

  Future<void> _processRecharge() async {
    double amount = _selectedAmount;
    if (_customAmountCtrl.text.trim().isNotEmpty) {
      final parsed = double.tryParse(_customAmountCtrl.text.trim().replaceAll('.', '').replaceAll(',', ''));
      if (parsed != null && parsed > 0) {
        amount = parsed;
      }
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido para recargar')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final res = await _walletRepo.recharge(
        amount: amount,
        paymentMethod: _selectedMethod,
      );

      if (mounted) {
        _customAmountCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              '¡Recarga exitosa de \$${_formatCurrency(amount)}! Ref: ${res.referenceCode}',
            ),
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Error al recargar: ${e.toString().replaceAll('Exception: ', '')}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _formatCurrency(double val) {
    return val.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Billetera Yireh',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Recarga y paga sin efectivo en la cafetería',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 18),

            // Card de saldo con gradiente elegante
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Saldo disponible',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _isLoadingBalance ? null : _loadData,
                        icon: _isLoadingBalance
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                        tooltip: 'Actualizar saldo',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '\$ ${_formatCurrency(_balance)} COP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Montos rápidos
            const Text(
              'Selecciona un monto',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quickAmounts.map((amount) {
                final isSelected = _selectedAmount == amount && _customAmountCtrl.text.isEmpty;
                return ChoiceChip(
                  label: Text('\$ ${_formatCurrency(amount)}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedAmount = amount;
                        _customAmountCtrl.clear();
                      });
                    }
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Monto personalizado
            TextField(
              controller: _customAmountCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Otro monto (COP)',
                hintText: 'Ej. 35000',
                prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Método de pago
            const Text(
              'Método de recarga',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MethodCard(
                    title: 'Nequi',
                    icon: Icons.phone_android_rounded,
                    isSelected: _selectedMethod == 'NEQUI',
                    onTap: () => setState(() => _selectedMethod = 'NEQUI'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MethodCard(
                    title: 'Daviplata',
                    icon: Icons.smartphone_rounded,
                    isSelected: _selectedMethod == 'DAVIPLATA',
                    onTap: () => setState(() => _selectedMethod = 'DAVIPLATA'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MethodCard(
                    title: 'Efectivo',
                    icon: Icons.storefront_rounded,
                    isSelected: _selectedMethod == 'CASH',
                    onTap: () => setState(() => _selectedMethod = 'CASH'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Botón de recarga
            ElevatedButton(
              onPressed: _isProcessing ? null : _processRecharge,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Recargar Billetera',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
            const SizedBox(height: 32),

            // Historial de transacciones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historial de Recargas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  '${_transactions.length} registros',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history_rounded, size: 36, color: AppColors.textHint.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      const Text(
                        'Aún no tienes recargas registradas',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final tx = _transactions[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.successSurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_downward_rounded, color: AppColors.success, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recarga ${tx.paymentMethod}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_formatDate(tx.createdAt)} • Ref: ${tx.referenceCode}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+ \$ ${_formatCurrency(tx.amount)}',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
