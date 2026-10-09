import 'package:models/models.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = await createTestContainer(
      config: StorageConfiguration(keepSignatures: false),
    );
  });

  tearDown(() async {
    container.dispose();
  });

  group('App', () {
    test('app', () {
      final partialApp = PartialApp()
        ..identifier = 'w'
        ..description = 'test app';
      final app = partialApp.dummySign(
        'f36f1a2727b7ab02e3f6e99841cd2b4d9655f8cfa184bd4d68f4e4c72db8e5c1',
      );

      expect(app.event.kind, 32267);
      expect(app.description, 'test app');
      expect(
        app.id,
        '32267:f36f1a2727b7ab02e3f6e99841cd2b4d9655f8cfa184bd4d68f4e4c72db8e5c1:w',
      );
      expect(app.event.id, hasLength(64));
      expect(
        app.event.shareableId,
        'naddr1qqqhwq3q7dh35fe8k74s9clkaxvyrnftfkt9t7x05xzt6ntg7njvwtdcuhqsxpqqqplqknw8nmm',
      );
      expect(App.fromMap(app.toMap(), container.ref), app);
    });
  });

  group('App.latestAsset', () {
    late ProviderContainer platformContainer;

    setUp(() async {
      platformContainer = await createTestContainer(
        config: StorageConfiguration(platform: 'android-arm64-v8a'),
      );
    });

    tearDown(() => platformContainer.tearDown());

    test('resolves the newest asset for the configured platform', () async {
      final pubkey = nielPubkey;
      final now = DateTime.now();

      final apk = PartialSoftwareAsset()
        ..appIdentifier = 'com.test.app'
        ..platforms = {'android-arm64-v8a', 'android-armeabi-v7a'};
      apk.event.createdAt = now.subtract(Duration(seconds: 7));
      final macZip = PartialSoftwareAsset()
        ..appIdentifier = 'com.test.app'
        ..platforms = {'darwin-arm64'};
      macZip.event.createdAt = now;
      final signedApk = apk.dummySign(pubkey);
      final signedMacZip = macZip.dummySign(pubkey);
      final app = (PartialApp()..identifier = 'com.test.app')
          .dummySign(pubkey);

      await platformContainer.storage.save({app, signedApk, signedMacZip});

      final loaded = (await platformContainer.storage.query(
        RequestFilter<App>(ids: {app.id}).toRequest(),
        source: LocalSource(),
      ))
          .single;
      expect(loaded.latestAsset.value?.id, signedApk.id);
    });
  });
}
