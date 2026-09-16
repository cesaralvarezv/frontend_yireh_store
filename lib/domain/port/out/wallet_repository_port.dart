import '../../../models/wallet_model.dart';

abstract class WalletRepositoryPort {
  Future<double> getBalance();
  Future<RechargeTransaction> recharge({
    required double amount,
    required String paymentMethod,
  });
  Future<List<RechargeTransaction>> getTransactions();
}
