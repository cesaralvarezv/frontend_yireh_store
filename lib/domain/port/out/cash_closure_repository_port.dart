import '../../../models/cash_closure_status_model.dart';

abstract class CashClosureRepositoryPort {
  Future<CashClosureStatusModel> getStatus();
}
