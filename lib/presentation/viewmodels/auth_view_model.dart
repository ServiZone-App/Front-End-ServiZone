import 'package:servizone_app/core/network/api_result.dart';
import 'package:servizone_app/domain/repositories/auth_repository.dart';
import 'package:servizone_app/presentation/viewmodels/base_view_model.dart';

class AuthViewModel extends BaseViewModel {
  final AuthRepository _repo;

  AuthViewModel(this._repo);

  bool get isLoggedIn => _repo.isLoggedIn;
  String? get currentRole => _repo.currentRole;
  Map<String, dynamic>? get currentUserProfile => _repo.currentUserProfile;

  Future<ApiResult<Map<String, dynamic>>> login(String email, String password) async {
    setBusy(true);
    clearError();
    final res = await _repo.login(email: email, password: password);
    if (!res.success) setError(res.message);
    setBusy(false);
    return res;
  }

  Future<ApiResult<bool>> autoLogin() async {
    setBusy(true);
    clearError();
    final res = await _repo.autoLogin();
    if (!res.success) setError(res.message);
    setBusy(false);
    return res;
  }

  Future<ApiResult<Map<String, dynamic>>> switchRole(String targetRole) async {
    setBusy(true);
    clearError();
    final res = await _repo.switchRole(targetRole);
    if (!res.success) setError(res.message);
    setBusy(false);
    return res;
  }

  Future<ApiResult<void>> logout() async {
    setBusy(true);
    clearError();
    final res = await _repo.logout();
    if (!res.success) setError(res.message);
    setBusy(false);
    return res;
  }
}

