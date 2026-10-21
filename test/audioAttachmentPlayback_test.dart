import 'package:eschool_saas_staff/data/models/studyMaterial.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/studyMaterialContainer.dart';
import 'package:eschool_saas_staff/ui/styles/colors.dart';
import 'package:eschool_saas_staff/ui/widgets/audioPlayerBottomsheetContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audio files a student submits for an assignment play inside the app on the
/// teacher's submission and review screens instead of being downloaded.
void main() {
  StudyMaterial material({
    String type = "1",
    String extension = "",
    String url = "https://example.com/storage/629/files/abc.bin",
  }) =>
      StudyMaterial.fromJson({
        'id': 1,
        'type': type,
        'file_name': 'Recitation',
        'file_url': url,
        'file_extension': extension,
      });

  group('isAudio', () {
    test('uploaded audio files are detected by their extension', () {
      for (final extension in ['mp3', 'MP3', '.m4a', 'aac', 'wav', 'mpga']) {
        expect(material(extension: extension).isAudio, isTrue,
            reason: extension);
      }
    });

    test('falls back to the url when the extension is missing', () {
      expect(
        material(url: 'https://example.com/storage/files/abc.mp3').isAudio,
        isTrue,
      );
      expect(
        material(url: 'https://example.com/files/abc.mp3?token=1').isAudio,
        isTrue,
        reason: 'query string is not part of the extension',
      );
      expect(material(url: 'https://example.com/files/abc').isAudio, isFalse);
    });

    test('other files are not treated as audio', () {
      for (final extension in ['jpeg', 'pdf', 'mp4', 'docx']) {
        expect(material(extension: extension).isAudio, isFalse,
            reason: extension);
      }
    });

    test('only uploaded files count, not videos or links', () {
      expect(material(type: "2", extension: 'mp3').isAudio, isFalse);
      expect(material(type: "3", extension: 'mp3').isAudio, isFalse);
      expect(material(type: "4", extension: 'mp3').isAudio, isFalse);
    });

    test('files built from a url are detected too', () {
      expect(
        StudyMaterial.fromURL('https://example.com/files/abc.m4a').isAudio,
        isTrue,
      );
    });
  });

  group('formatPlaybackTime', () {
    String format(Duration duration) =>
        AudioPlayerBottomsheetContainer.formatPlaybackTime(duration);

    test('formats minutes and seconds', () {
      expect(format(Duration.zero), '0:00');
      expect(format(const Duration(seconds: 9)), '0:09');
      expect(format(const Duration(seconds: 60)), '1:00');
      expect(format(const Duration(minutes: 12, seconds: 5)), '12:05');
      expect(format(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('adds hours from one hour on', () {
      expect(format(const Duration(hours: 1)), '1:00:00');
      expect(format(const Duration(hours: 2, minutes: 3, seconds: 4)),
          '2:03:04');
    });

    test('drops milliseconds and never goes negative', () {
      expect(format(const Duration(seconds: 5, milliseconds: 999)), '0:05');
      expect(format(const Duration(seconds: -3)), '0:00');
    });
  });

  group('submission file tile', () {
    Future<void> pumpTile(WidgetTester tester, StudyMaterial studyMaterial) {
      return tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: <ThemeExtension<dynamic>>[customColorsExtension],
          ),
          home: Scaffold(
            // Same configuration as the submission list and review screens.
            body: StudyMaterialContainer(
              showOnlyStudyMaterialTitles: true,
              showEditAndDeleteButton: false,
              studyMaterial: studyMaterial,
            ),
          ),
        ),
      );
    }

    testWidgets('audio files get a play button', (tester) async {
      await pumpTile(tester, material(extension: 'mp3'));
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.download), findsNothing);
    });

    testWidgets('other files keep the download button', (tester) async {
      await pumpTile(tester, material(extension: 'pdf'));
      expect(find.byIcon(Icons.download), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });
  });
}
