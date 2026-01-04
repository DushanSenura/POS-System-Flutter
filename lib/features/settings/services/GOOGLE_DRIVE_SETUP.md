# Google Drive Integration Setup Guide

This guide explains how to integrate real Google Drive functionality for backup and restore features.

## Current Implementation

The current implementation is a **mock service** for demonstration purposes. It simulates Google Drive operations locally without actually connecting to Google Drive.

## Production Setup (Required Steps)

To enable real Google Drive integration, follow these steps:

### 1. Add Dependencies

Update `pubspec.yaml` to include:

```yaml
dependencies:
  # Existing dependencies...
  
  # Google Drive Integration
  googleapis: ^13.2.0
  googleapis_auth: ^1.6.0
  google_sign_in: ^6.2.1
  extension_google_sign_in_as_googleapis_auth: ^2.0.12
```

Run: `flutter pub get`

### 2. Set Up Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable **Google Drive API**:
   - Navigate to "APIs & Services" > "Library"
   - Search for "Google Drive API"
   - Click "Enable"

### 3. Configure OAuth 2.0 Credentials

#### For Android:

1. In Google Cloud Console, go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Select "Android" as application type
4. Get your SHA-1 fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
5. Enter package name: `com.yourcompany.pos_management_system`
6. Enter SHA-1 fingerprint
7. Create and download credentials

#### For iOS:

1. Create OAuth client ID for iOS
2. Enter bundle ID from `ios/Runner/Info.plist`
3. Download and save the client ID

#### For Web:

1. Create OAuth client ID for Web application
2. Add authorized JavaScript origins
3. Add authorized redirect URIs

### 4. Update Android Configuration

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
  <application ...>
    <!-- Add this inside <application> tag -->
    <meta-data
      android:name="com.google.android.gms.version"
      android:value="@integer/google_play_services_version" />
  </application>
</manifest>
```

### 5. Update iOS Configuration

Edit `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Add your REVERSED_CLIENT_ID here -->
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### 6. Implement Real Google Drive Service

Replace the mock `google_drive_service.dart` with:

```dart
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:intl/intl.dart';

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  Future<bool> isSignedIn() async {
    _currentUser = await _googleSignIn.signInSilently();
    return _currentUser != null;
  }

  Future<String?> getUserEmail() async {
    return _currentUser?.email;
  }

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) return false;

      final authHeaders = await _currentUser!.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(authenticateClient);
      
      return true;
    } catch (e) {
      print('Error signing in: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
  }

  Future<List<Map<String, dynamic>>> listBackupFiles() async {
    if (_driveApi == null) throw Exception('Not signed in');

    try {
      final fileList = await _driveApi!.files.list(
        q: "name contains 'pos_backup_' and trashed = false",
        orderBy: 'modifiedTime desc',
        spaces: 'drive',
        $fields: 'files(id, name, size, modifiedTime)',
      );

      return fileList.files?.map((file) {
        return {
          'id': file.id!,
          'name': file.name!,
          'size': _formatBytes(int.parse(file.size ?? '0')),
          'modifiedTime': DateFormat('MMM dd, yyyy HH:mm')
              .format(file.modifiedTime ?? DateTime.now()),
        };
      }).toList() ?? [];
    } catch (e) {
      print('Error listing files: $e');
      return [];
    }
  }

  Future<bool> uploadBackup(File file, String fileName) async {
    if (_driveApi == null) throw Exception('Not signed in');

    try {
      final driveFile = drive.File()..name = fileName;
      final media = drive.Media(file.openRead(), file.lengthSync());
      
      await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );
      
      return true;
    } catch (e) {
      print('Error uploading file: $e');
      return false;
    }
  }

  Future<bool> downloadBackup(String fileId, File destinationFile) async {
    if (_driveApi == null) throw Exception('Not signed in');

    try {
      final drive.Media media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await media.stream.toBytes();
      await destinationFile.writeAsBytes(bytes);
      
      return true;
    } catch (e) {
      print('Error downloading file: $e');
      return false;
    }
  }

  Future<bool> deleteBackup(String fileId) async {
    if (_driveApi == null) throw Exception('Not signed in');

    try {
      await _driveApi!.files.delete(fileId);
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class GoogleAuthClient extends BaseClient {
  final Map<String, String> _headers;
  final Client _client = Client();

  GoogleAuthClient(this._headers);

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
```

### 7. Permissions

#### Android:
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

#### iOS:
Permissions are automatically handled by the packages.

### 8. Testing

1. Build and run the app
2. Navigate to Settings > Backup & Restore
3. Sign in with your Google account
4. Test backup creation
5. Test backup restoration
6. Test backup deletion

## Features

- ✅ Sign in with Google account
- ✅ Create backups to Google Drive
- ✅ List all backups from Google Drive
- ✅ Restore data from backups
- ✅ Delete old backups
- ✅ Automatic file naming with timestamps
- ✅ File size display
- ✅ Secure OAuth 2.0 authentication

## Security Notes

- Backups are stored in the user's Google Drive
- Only the app can access its own backup files
- Data is transmitted over secure HTTPS
- OAuth tokens are managed by Google Sign-In
- No passwords are stored locally

## Troubleshooting

### Sign-in fails:
- Verify OAuth credentials are correctly configured
- Check SHA-1 fingerprint matches
- Ensure Google Drive API is enabled
- Check package name matches credentials

### Upload fails:
- Check internet connection
- Verify Google Drive has enough space
- Check file permissions
- Ensure API scopes are correct

### Download fails:
- Check internet connection
- Verify file still exists on Google Drive
- Check local storage permissions
- Ensure sufficient local storage space

## Support

For issues with Google Drive integration:
- [Google Sign-In Documentation](https://pub.dev/packages/google_sign_in)
- [Google APIs Documentation](https://pub.dev/packages/googleapis)
- [Google Cloud Console](https://console.cloud.google.com/)
