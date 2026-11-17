import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opportune_jobmate/core/api_client.dart';
import 'package:opportune_jobmate/core/api_config.dart';

void main() {
  setUp(() {
    dotenv.clean();
  });

  tearDown(() {
    dotenv.clean();
  });

  group('Environment Configuration & Precedence', () {
    test('Default fallback is the production Render URL when .env is empty',
        () {
      expect(
        kApiBaseUrl,
        equals('https://opportune-jobmate-api.onrender.com'),
      );
      expect(ApiConfig.baseUrl,
          equals('https://opportune-jobmate-api.onrender.com'));
      expect(kAppEnv, equals('production'));
      expect(kApiTimeoutSeconds, equals(60));
      expect(kApiTimeout, equals(const Duration(seconds: 60)));
    });

    test('.env values override fallback when loaded', () {
      dotenv.loadFromString(envString: '''
API_BASE_URL=https://custom-api.example.com/
APP_ENV=staging
API_TIMEOUT_SECONDS=45
''');

      // Trailing slash should be cleanly stripped
      expect(kApiBaseUrl, equals('https://custom-api.example.com'));
      expect(kAppEnv, equals('staging'));
      expect(kApiTimeoutSeconds, equals(45));
      expect(kApiTimeout, equals(const Duration(seconds: 45)));
    });

    test('initEnvironment does not throw even if .env file is missing',
        () async {
      // Calling initEnvironment when asset bundle or file might not be present
      await expectLater(initEnvironment(), completes);
    });

    test('ApiClient uses kApiBaseUrl and kApiTimeout by default', () {
      final client = ApiClient();
      expect(
        client.baseUrl,
        equals('https://opportune-jobmate-api.onrender.com'),
      );
      expect(client.timeout, equals(const Duration(seconds: 60)));
    });

    test('ApiClient allows overriding baseUrl and timeout explicitly', () {
      final customClient = ApiClient(
        baseUrl: 'http://127.0.0.1:8000',
        timeout: const Duration(seconds: 15),
      );
      expect(customClient.baseUrl, equals('http://127.0.0.1:8000'));
      expect(customClient.timeout, equals(const Duration(seconds: 15)));
    });
  });
}
