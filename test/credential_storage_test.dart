import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yireh_store/services/credential_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('guarda, carga y limpia las credenciales recordadas', () async {
    expect(await CredentialStorage.load(), isNull);

    await CredentialStorage.save(
      email: 'admin@yirehstore.com',
      password: 'Admin123456',
    );

    final saved = await CredentialStorage.load();
    expect(saved, isNotNull);
    expect(saved!.email, 'admin@yirehstore.com');
    expect(saved.password, 'Admin123456');

    await CredentialStorage.clear();
    expect(await CredentialStorage.load(), isNull);
  });

  test('no devuelve credenciales si están incompletas', () async {
    SharedPreferences.setMockInitialValues({
      'remember_credentials': true,
      'remembered_email': 'admin@yirehstore.com',
    });

    expect(await CredentialStorage.load(), isNull);
  });
}
