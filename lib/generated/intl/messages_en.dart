// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "main_anErrorOccurredTapToView" : MessageLookupByLibrary.simpleMessage("An error occurred. Tap to view."),
    "main_check_location_permission" : MessageLookupByLibrary.simpleMessage("Checking location permission..."),
    "main_checkingStoragePermission" : MessageLookupByLibrary.simpleMessage("Checking storage permission..."),
    "main_fencesLoaded" : MessageLookupByLibrary.simpleMessage("Fences loaded."),
    "main_knownProjectionsLoaded" : MessageLookupByLibrary.simpleMessage("Known projections loaded."),
    "main_layersListLoaded" : MessageLookupByLibrary.simpleMessage("Layers list loaded."),
    "main_loadingFences" : MessageLookupByLibrary.simpleMessage("Loading fences..."),
    "main_loadingKnownProjections" : MessageLookupByLibrary.simpleMessage("Loading known projections..."),
    "main_loadingLayersList" : MessageLookupByLibrary.simpleMessage("Loading layers list..."),
    "main_loadingPreferences" : MessageLookupByLibrary.simpleMessage("Loading preferences..."),
    "main_loadingTagsList" : MessageLookupByLibrary.simpleMessage("Loading tags list..."),
    "main_loadingWorkspace" : MessageLookupByLibrary.simpleMessage("Loading workspace..."),
    "main_locationBackgroundWarning" : MessageLookupByLibrary.simpleMessage("This app collects location data to your device to enable gps logs recording even when the app is placed in background. No data is shared, it is only saved locally to the device.\n\nIf you do not give permission to the background location service in the next dialog, you will still be able to collect data with SMASH, but will need to keep the app always in foreground to do so.\n"),
    "main_locationPermissionIsMandatoryToOpenSmash" : MessageLookupByLibrary.simpleMessage("Location permission is mandatory to open SMASH."),
    "main_location_permission_granted" : MessageLookupByLibrary.simpleMessage("Location permission granted."),
    "main_preferencesLoaded" : MessageLookupByLibrary.simpleMessage("Preferences loaded."),
    "main_storagePermissionGranted" : MessageLookupByLibrary.simpleMessage("Storage permission granted."),
    "main_storagePermissionIsMandatoryToOpenSmash" : MessageLookupByLibrary.simpleMessage("Storage permission is mandatory to open SMASH."),
    "main_tagsListLoaded" : MessageLookupByLibrary.simpleMessage("Tags list loaded."),
    "main_welcome" : MessageLookupByLibrary.simpleMessage("Welcome to SMASH!"),
    "main_workspaceLoaded" : MessageLookupByLibrary.simpleMessage("Workspace loaded.")
  };
}
