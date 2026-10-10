import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/user_model.dart';
import '../../models/wallet_model.dart';
import '../../services/wallet_service.dart';
import '../../theme/app_colors.dart';

/// Vista de billetera con QR para pago en POS (mostrador).
/// El QR codifica un payload JSON: {email, balance, ts} que el cajero puede escanear.
class WalletQrView extends StatefulWidget {
  final UserModel user;
  final WalletService? walletService;

  const WalletQrView({super.key, required this.user, this.walletService});

  @override
  State<WalletQrView> createState() => _WalletQrViewState();
}

class _WalletQrViewState extends State<WalletQrView>
    with SingleTickerProviderStateMixin {
  late final WalletService _service;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  WalletBalance? _balance;
  List<RechargeTransaction> _transactions = [];
  bool _loadingBalance = true;
  bool _loadingTx = true;
  String get _qrData {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return jsonEncode({
      'type': 'YIREH_WALLET',
      'email': widget.user.email,
      'balance': _balance?.balance ?? 0.0,
      'ts': ts,
    });
  }

  @override
  void initState() {
    super.initState();
    _service = widget.walletService ?? WalletService();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _loadAll();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadBalance(), _loadTransactions()]);
  }

  Future<void> _loadBalance() async {
    setState(() => _loadingBalance = true);
    try {
      final b = await _service.getBalance();
      if (mounted) setState(() { _balance = b; _loadingBalance = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingBalance = false);
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _loadingTx = true);
    try {
      final txs = await _service.getTransactions();
      if (mounted) setState(() { _transactions = txs; _loadingTx = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingTx = false);
    }
  }

  String _formatCurrency(double v) => '\$ ${v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mi Billetera',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadAll,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Saldo header ─────────────────────────────────────
              _BalanceCard(
                balance: _balance,
                loading: _loadingBalance,
                userEmail: widget.user.email,
                userName: widget.user.name,
              ),
              const SizedBox(height: 24),

              // ─── QR de pago ───────────────────────────────────────
              _QrCard(qrData: _qrData, pulse: _pulse, onCopy: _copyEmail),
              const SizedBox(height: 24),

              // ─── Historial de movimientos ─────────────────────────
              _TransactionHistory(
                transactions: _transactions,
                loading: _loadingTx,
                formatCurrency: _formatCurrency,
                formatDate: _formatDate,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyEmail() {
    Clipboard.setData(ClipboardData(text: widget.user.email));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email copiado al portapapeles'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

// ─── Balance card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final WalletBalance? balance;
  final bool loading;
  final String userEmail;
  final String userName;

  const _BalanceCard({
    required this.balance,
    required this.loading,
    required this.userEmail,
    required this.userName,
  });

  String _fmt(double v) => '\$ ${v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text(userEmail,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Saldo disponible',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          loading
              ? const SizedBox(
                  height: 40,
                  width: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  balance != null ? _fmt(balance!.balance) : '---',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── QR Card ──────────────────────────────────────────────────────────────────

class _QrCard extends StatelessWidget {
  final String qrData;
  final Animation<double> pulse;
  final VoidCallback onCopy;

  const _QrCard({
    required this.qrData,
    required this.pulse,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'QR de pago en mostrador',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Muestra este codigo al cajero para pagar con tu billetera',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ScaleTransition(
            scale: pulse,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primaryDark,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copiar email'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'El QR se regenera automaticamente',
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ─── Transaction history ──────────────────────────────────────────────────────

class _TransactionHistory extends StatelessWidget {
  final List<RechargeTransaction> transactions;
  final bool loading;
  final String Function(double) formatCurrency;
  final String Function(DateTime) formatDate;

  const _TransactionHistory({
    required this.transactions,
    required this.loading,
    required this.formatCurrency,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Estado de cuenta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (!loading)
              Text(
                '${transactions.length} movimientos',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (transactions.isEmpty)
          _EmptyTransactions()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final tx = transactions[i];
              return _TransactionTile(
                tx: tx,
                formatCurrency: formatCurrency,
                formatDate: formatDate,
              );
            },
          ),
      ],
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 40, color: AppColors.textHint.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          const Text(
            'Sin movimientos aun',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final RechargeTransaction tx;
  final String Function(double) formatCurrency;
  final String Function(DateTime) formatDate;

  const _TransactionTile({
    required this.tx,
    required this.formatCurrency,
    required this.formatDate,
  });

  IconData get _icon {
    switch (tx.paymentMethod.toUpperCase()) {
      case 'NEQUI':
        return Icons.phone_android_rounded;
      case 'DAVIPLATA':
        return Icons.smartphone_rounded;
      case 'WALLET':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

  Color get _statusColor =>
      tx.status == 'COMPLETED' ? AppColors.success : AppColors.warning;

  @override
  Widget build(BuildContext context) {
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
            child: Icon(_icon, color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recarga ${tx.paymentMethod}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatDate(tx.createdAt)} • Ref: ${tx.referenceCode}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+ ${formatCurrency(tx.amount)}',
                style: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tx.status,
                  style: TextStyle(fontSize: 10, color: _statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

