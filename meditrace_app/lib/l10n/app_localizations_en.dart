// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeToMeditrace => 'Welcome to MEDITRACE';

  @override
  String get signInToUseFamilyFeaturesAndAccount =>
      'Sign in to use family features and account sync, or continue as a guest to use local features.';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get signIn => 'Sign in';

  @override
  String get meditraceUser => 'MEDITRACE User';

  @override
  String get myFamily => 'My Family';

  @override
  String get medicationTakenBasedOnRemoval =>
      'Medication taken based on removal.';

  @override
  String get early => 'early';

  @override
  String get onTime => 'on time';

  @override
  String get late => 'late';

  @override
  String medicationTaken(String arg0) {
    return 'Medication taken $arg0.';
  }

  @override
  String get medicationStatusTaken => 'Medication status: taken';

  @override
  String medicationScheduledAsWasRecordedAsTaken(String arg0, String arg1) {
    return 'Medication scheduled as $arg0 was recorded as taken ($arg1).';
  }

  @override
  String get early2 => 'early';

  @override
  String get recorded => 'recorded';

  @override
  String get theFirmwareFileIsEmpty => 'The firmware file is empty.';

  @override
  String compartmentIsEmpty(String arg0) {
    return 'Compartment $arg0 is empty';
  }

  @override
  String meditraceDetectedThatCompartmentIsEmptyCheckAnd(String arg0) {
    return 'MEDITRACE detected that compartment $arg0 is empty. Check and refill the medication.';
  }

  @override
  String get meditraceDisconnectedFromPhone =>
      'MEDITRACE disconnected from phone';

  @override
  String get thePatientWasWarnedAfterSecondsMeditraceHas =>
      'The patient was warned after 30 seconds. MEDITRACE has not reconnected 5 minutes later. Check the device distance and power.';

  @override
  String get patientReportedMeditraceLeftBehind =>
      'Patient reported MEDITRACE left behind';

  @override
  String get thePatientConfirmedThatTheMeditraceMedicationBox =>
      'The patient confirmed that the MEDITRACE medication box was left behind.';

  @override
  String get couldNotSendTheAlertCheckYourSign =>
      'Could not send the alert. Check your sign-in and family group.';

  @override
  String medicationInCompartmentWasRecordedAsTaken(String arg0, String arg1) {
    return 'Medication in compartment $arg0 was recorded as taken ($arg1).';
  }

  @override
  String compartment(String arg0) {
    return ' compartment $arg0';
  }

  @override
  String medicationScheduleCompartmentEmptyRefillFirst(String arg0) {
    return 'Medication schedule$arg0: compartment empty, refill first.';
  }

  @override
  String timeToTakeMedication(String arg0) {
    return 'Time to take medication$arg0.';
  }

  @override
  String get meditraceConnected => 'MEDITRACE connected';

  @override
  String get connectingToMeditrace => 'Connecting to MEDITRACE';

  @override
  String get meditraceNotConnected => 'MEDITRACE not connected';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get noMeditrace => 'No MEDITRACE';

  @override
  String get refreshMeditraceStatus => 'Refresh MEDITRACE status';

  @override
  String get deviceDetails => 'Device details';

  @override
  String get batterySignalAndTechnicalInformation =>
      'Battery, signal, and technical information';

  @override
  String get estimatedBattery => 'Estimated battery';

  @override
  String get battery => 'Battery';

  @override
  String get estimatedRuntime => 'Estimated runtime';

  @override
  String get estimatedFromAMahBatteryAndAnAverage =>
      'Estimated from a 1500 mAh battery and an average current of 150 mA (about 10 hours). Assumes a full battery on first use. After fully charging, mark it as full below. Charging is not detected automatically.';

  @override
  String get markBatteryAsFull => 'Mark battery as full';

  @override
  String get signalStrength => 'Signal strength';

  @override
  String get deviceId => 'Device ID';

  @override
  String get scheduleSource => 'Schedule source';

  @override
  String get unsentEvents => 'Unsent events';

  @override
  String get espCFirmware => 'ESP32-C3 firmware';

  @override
  String get theLatestUpdateIsDownloadedFromGithubReleases =>
      'The latest update is downloaded from GitHub Releases and sent to the device over BLE.';

  @override
  String get updateToLatestFirmware => 'Update to latest firmware';

  @override
  String get chooseLocalBinFile => 'Choose local .bin file';

  @override
  String sendingFirmware(String arg0) {
    return 'Sending firmware $arg0%...';
  }

  @override
  String get firmwareSentTheDeviceIsRestarting =>
      'Firmware sent. The device is restarting.';

  @override
  String get findMeditrace => 'Find MEDITRACE';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get meditraceDevice => 'MEDITRACE device';

  @override
  String get isTheBatteryFullyCharged => 'Is the battery fully charged?';

  @override
  String get theEstimateWillRestartFromUseThisOnly =>
      'The estimate will restart from 100%. Use this only after the battery is fully charged.';

  @override
  String get cancel => 'Cancel';

  @override
  String get markAsFull => 'Mark as full';

  @override
  String couldNotDownloadFirmware(String arg0) {
    return 'Could not download firmware: $arg0';
  }

  @override
  String get updateFirmware => 'Update firmware?';

  @override
  String theDeviceWillRestartAfterTheUpdateBytes(String arg0) {
    return 'The device will restart after the update. $arg0 bytes will be sent over BLE.';
  }

  @override
  String get disconnectMeditrace => 'Disconnect MEDITRACE?';

  @override
  String get afterDisconnectingMeditraceWillNotReconnectAutomaticallyYou =>
      'After disconnecting, MEDITRACE will not reconnect automatically. You will need to connect it again manually.';

  @override
  String get stopScanning => 'Stop scanning';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get close => 'Close';

  @override
  String get noMeditraceFoundYetMakeSureTheMedication =>
      'No MEDITRACE found yet.\nMake sure the medication box is powered on, Bluetooth is enabled, and it is close to your phone.';

  @override
  String get tapToConnect => 'Tap to connect';

  @override
  String get history => 'History';

  @override
  String get clearLocalHistory => 'Clear local history';

  @override
  String get noHistoryYet => 'No history yet';

  @override
  String get medicationAndDeviceActivityWillAppearHere =>
      'Medication and device activity will appear here.';

  @override
  String compartment2(String arg0) {
    return ' · Compartment $arg0';
  }

  @override
  String get clearAllHistory => 'Clear all history?';

  @override
  String get allLocalActivityWillBeDeletedAndCannot =>
      'All local activity will be deleted and cannot be recovered.';

  @override
  String get delete => 'Delete';

  @override
  String get medicationRemoved => 'Medication removed';

  @override
  String get compartmentFilled => 'Compartment filled';

  @override
  String get compartmentEmpty => 'Compartment empty';

  @override
  String get compartmentClosed => 'Compartment closed';

  @override
  String get compartmentOpened => 'Compartment opened';

  @override
  String get medicationReminder => 'Medication reminder';

  @override
  String medicationTaken2(String arg0) {
    return 'Medication taken · $arg0';
  }

  @override
  String get medicationConfirmationRevoked => 'Medication confirmation revoked';

  @override
  String get medicationScheduleMissed => 'Medication schedule missed';

  @override
  String get meditracePoweredBackOnAndConnected =>
      'MEDITRACE powered back on and connected';

  @override
  String get meditracePoweredOnAndConnected =>
      'MEDITRACE powered on and connected';

  @override
  String get meditraceConnectionLost => 'MEDITRACE connection lost';

  @override
  String get warningMeditraceNotDetected => 'Warning: MEDITRACE not detected';

  @override
  String get alertSentToFamily => 'Alert sent to family';

  @override
  String get meditraceReconnected => 'MEDITRACE reconnected';

  @override
  String get meditraceReportedLeftBehind => 'MEDITRACE reported left behind';

  @override
  String get deviceActivity => 'Device activity';

  @override
  String get familyNotifications => 'Family notifications';

  @override
  String get alertsForCaregiversAndFamilyMembers =>
      'Alerts for caregivers and family members';

  @override
  String get noFamilyNotificationsYet => 'No family notifications yet';

  @override
  String get familyAlert => 'Family alert';

  @override
  String get family => 'Family';

  @override
  String get senderEmailUnavailable => 'Sender email unavailable';

  @override
  String get acknowledge => 'Acknowledge';

  @override
  String get meditraceLogo => 'MEDITRACE logo';

  @override
  String get home => 'Home';

  @override
  String get schedule => 'Schedule';

  @override
  String get device => 'Device';

  @override
  String get profile => 'Profile';

  @override
  String get connectMeditraceToRefreshItsStatus =>
      'Connect MEDITRACE to refresh its status.';

  @override
  String get welcome => 'Welcome!';

  @override
  String get keepTrackOfYourMedicationScheduleToday =>
      'Keep track of your medication schedule today.';

  @override
  String get meditraceActive => 'MEDITRACE active';

  @override
  String get connectDevice => 'Connect device';

  @override
  String get estimatedFromUsageTimeRatherThanVoltageMeasurement =>
      'Estimated from usage time, rather than voltage measurement.';

  @override
  String get weakSignal => 'Weak signal';

  @override
  String get keepMeditraceNearby => 'Keep MEDITRACE nearby.';

  @override
  String get nextSchedule => 'Next schedule';

  @override
  String get noMedicationSchedulesYet => 'No medication schedules yet';

  @override
  String get waitForTheNextMedicationSchedule =>
      'Wait for the next medication schedule';

  @override
  String get medicationIsNotAvailableInThisCompartmentYet =>
      'Medication is not available in this compartment yet.';

  @override
  String get viewMedicationSchedule => 'View medication schedule';

  @override
  String get taken => 'Taken';

  @override
  String get medicationBox => 'Medication box';

  @override
  String get viewAll => 'View all';

  @override
  String get compartmentStatus => 'Compartment status';

  @override
  String get complete => 'Complete';

  @override
  String get needsRefill => 'Needs refill';

  @override
  String ofCompartmentsFilled(String arg0, String arg1) {
    return '$arg0 of $arg1 compartments filled';
  }

  @override
  String get connectMeditraceToSeeContents =>
      'Connect MEDITRACE to see contents';

  @override
  String get allCompartmentsAreFilled => 'All compartments are filled.';

  @override
  String get refillMedicationBeforeTheNextSchedule =>
      'Refill medication before the next schedule.';

  @override
  String get medicationSchedule => 'Medication Schedule';

  @override
  String get addAReminderToAvoidMissingMedication =>
      'Add a reminder to avoid missing medication.';

  @override
  String get addSchedule => 'Add schedule';

  @override
  String get everyDay => 'Every day';

  @override
  String get scheduleActions => 'Schedule actions';

  @override
  String get deleteSchedule => 'Delete schedule';

  @override
  String get takenTodayUndo => 'Taken today · undo';

  @override
  String get deleteMedicationSchedule => 'Delete medication schedule?';

  @override
  String scheduleAtWillBeDeleted(String arg0, String arg1) {
    return 'Schedule $arg0 at $arg1 will be deleted.';
  }

  @override
  String get scheduleDeleted => 'Schedule deleted.';

  @override
  String get haveYouTakenTheMedication => 'Have you taken the medication?';

  @override
  String get revokeConfirmation => 'Revoke confirmation?';

  @override
  String get confirmOnlyIfTheMedicationFromThisCompartment =>
      'Confirm only if the medication from this compartment has actually been taken, rather than simply removed from the box.';

  @override
  String get todaySTakenStatusWillBeRevoked =>
      'Today\'s taken status will be revoked.';

  @override
  String get back => 'Back';

  @override
  String get yesTaken => 'Yes, taken';

  @override
  String get revokeStatus => 'Revoke status';

  @override
  String get medicationSchedule2 => 'Medication schedule';

  @override
  String get scheduleAdded => 'Schedule added.';

  @override
  String get scheduleUpdated => 'Schedule updated.';

  @override
  String get save => 'Save';

  @override
  String get caregiverInvitationCode => 'Caregiver invitation code';

  @override
  String get validForDaysAndCanOnlyBeUsed =>
      'Valid for 7 days and can only be used once.';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get copyCode => 'Copy code';

  @override
  String get sendViaEmail => 'Send via email';

  @override
  String get sendInvitationViaEmail => 'Send invitation via email';

  @override
  String get recipientEmail => 'Recipient email';

  @override
  String get sendEmail => 'Send email';

  @override
  String get enterAValidEmailAddress => 'Enter a valid email address.';

  @override
  String get editFamilyName => 'Edit family name';

  @override
  String get familyName => 'Family name';

  @override
  String get deleteFamilyGroup => 'Delete family group?';

  @override
  String groupWillBeDeletedAndMembersWillLose(String arg0) {
    return 'Group \"$arg0\" will be deleted and members will lose access. This action cannot be undone.';
  }

  @override
  String get signInUsingTheProfileCardAboveTo =>
      'Sign in using the Profile card above to manage groups and share alerts with your family.';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get accountConnected => 'Account connected';

  @override
  String get signOut => 'Sign out';

  @override
  String get groupSettingsAreNotActiveYet =>
      'Group settings are not active yet';

  @override
  String get localFeaturesRemainAvailableConnectTheBackendTo =>
      'Local features remain available. Connect the backend to manage your family.';

  @override
  String get familyGroups => 'Family groups';

  @override
  String get alertsForEmptyCompartmentsAndMeditraceDisconnectionsAre =>
      'Alerts for empty compartments and MEDITRACE disconnections are sent to groups you own. Manual disconnections do not send alerts.';

  @override
  String get familyAlertsActive => 'Family alerts active';

  @override
  String get meditraceWillSendAlertsToYourFamilyGroup =>
      'MEDITRACE will send alerts to your family group.';

  @override
  String get inviteCaregiver => 'Invite caregiver';

  @override
  String get editName => 'Edit name';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String get user => 'User';

  @override
  String get emailNotRegisteredYet => 'Email not registered yet';

  @override
  String get owner => 'Owner';

  @override
  String get createGroup => 'Create group';

  @override
  String get createFamilyGroup => 'Create family group';

  @override
  String get joinGroup => 'Join group';

  @override
  String get invitationCode => 'Invitation code';

  @override
  String get enterInvitationCode => 'Enter invitation code';

  @override
  String get invalidFamilyGroupId => 'Invalid family group ID.';

  @override
  String get medicationUsageGuide => 'Medication usage guide';

  @override
  String get importantNote => 'Important note';

  @override
  String get thisIsGeneralInformationAndDoesNotReplace =>
      'This is general information and does not replace instructions from your doctor, pharmacist, or medication label.';

  @override
  String get whyDoesSchedulingMatter => 'Why does scheduling matter?';

  @override
  String get takingMedicationRegularlyAccordingToYourTreatmentPlan =>
      'Taking medication regularly according to your treatment plan helps it work as intended. Use MEDITRACE reminders for support and follow your prescription instructions.';

  @override
  String get doNotChangeTheDoseYourself => 'Do not change the dose yourself';

  @override
  String get skippingDelayingOrTakingDosesTooCloseTogether =>
      'Skipping, delaying, or taking doses too close together can reduce benefits or increase the risk of side effects. Do not stop, increase, or double a dose without guidance from your doctor or pharmacist.';

  @override
  String get ifYouForgetADose => 'If you forget a dose';

  @override
  String get instructionsVaryBetweenMedicationsCheckTheLabelOr =>
      'Instructions vary between medications. Check the label or leaflet and contact your doctor or pharmacist if unsure. Do not automatically double a dose to make up for a missed one.';

  @override
  String get practicalGuide => 'Practical guide';

  @override
  String get fillCompartmentsAccordingToThePrescriptionAndOriginal =>
      '• Fill compartments according to the prescription and original medication label.\n• Tap “Taken” after the medication has actually been taken or used as instructed.\n• Record or ask about any bothersome effects.\n• Do not crush tablets or open capsules without guidance from a healthcare professional.';

  @override
  String get whenDoYouNeedUrgentHelp => 'When do you need urgent help?';

  @override
  String get contactLocalEmergencyServicesImmediatelyIfYouDevelop =>
      'Contact local emergency services immediately if you develop difficulty breathing or swelling of the face, lips, mouth, or throat after taking medication. For other concerning symptoms, contact your doctor or pharmacist.';

  @override
  String get referenceNhsGuidanceOnDelayedDosesMedicationManagement =>
      'Reference: NHS guidance on delayed doses, medication management, and supporting someone with their medication.';

  @override
  String get familyInvitation => 'Family invitation';

  @override
  String invitationCodeIsReadyToUse(String arg0) {
    return 'Invitation code $arg0 is ready to use.';
  }

  @override
  String get later => 'Later';

  @override
  String get joinNow => 'Join now';

  @override
  String enterCodeInTheFamilySection(String arg0) {
    return 'Enter code $arg0 in the Family section';
  }

  @override
  String get accountEmailUnavailable => 'Account email unavailable';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get completeProfile => 'Complete profile';

  @override
  String get signOutOfAccount => 'Sign out of account';

  @override
  String get healthInformation => 'Health information';

  @override
  String get patientInformationAndEmergencyContacts =>
      'Patient information and emergency contacts';

  @override
  String get ageNotProvided => 'Age not provided';

  @override
  String ageYears(String arg0) {
    return 'Age $arg0 years';
  }

  @override
  String get emergencyContactNotProvided => 'Emergency contact not provided';

  @override
  String get emergencyContactSaved => 'Emergency contact saved';

  @override
  String get updateApp => 'Update app';

  @override
  String get downloadTheLatestMeditraceApkFromGithubReleases =>
      'Download the latest MEDITRACE APK from GitHub Releases.';

  @override
  String get manageGroupsCaregiversAndNotifications =>
      'Manage groups, caregivers, and notifications';

  @override
  String get signInToConnectWithFamily => 'Sign in to connect with family';

  @override
  String get reminderWhenMeditraceIsLeftBehind =>
      'Reminder when MEDITRACE is left behind';

  @override
  String get thePatientIsWarnedSecondsAfterDisconnectionIf =>
      'The patient is warned 30 seconds after disconnection. If it has not reconnected 5 minutes later, the caregiver is notified.';

  @override
  String get alertSavedButTheCaregiverEmailCouldNot =>
      'Alert saved, but the caregiver email could not be sent.';

  @override
  String alertSentToCaregiverEmailAddresses(String arg0) {
    return 'Alert sent to $arg0 caregiver email addresses.';
  }

  @override
  String get alertSavedAndBeingProcessedForTheCaregiver =>
      'Alert saved and being processed for the caregiver.';

  @override
  String get iLeftMeditraceBehind => 'I left MEDITRACE behind';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get userName => 'User name';

  @override
  String get exampleBudiSFamily => 'Example: Budi\'s Family';

  @override
  String get emergencyPhoneNumber => 'Emergency phone number';

  @override
  String get emergencyEmail => 'Emergency email';

  @override
  String get notAvailableYet => 'Not available yet';

  @override
  String hrMin(String arg0, String arg1) {
    return '$arg0 hr $arg1 min';
  }

  @override
  String get alertsFromCaregiversAndFamilyMembers =>
      'Alerts from caregivers and family members';

  @override
  String get timeToTakeMedication2 => 'Time to take medication';

  @override
  String openMeditraceNow(String arg0, String arg1) {
    return '$arg0 • $arg1. Open MEDITRACE now.';
  }

  @override
  String checkCompartment(String arg0, String arg1, String arg2) {
    return '$arg0 • $arg1. Check compartment $arg2.';
  }

  @override
  String get dailyMeditraceMedicationReminders =>
      'Daily MEDITRACE medication reminders';

  @override
  String get meditraceNotDetected => 'MEDITRACE not detected';

  @override
  String get makeSureTheMedicationBoxHasNotBeen =>
      'Make sure the medication box has not been left behind.';

  @override
  String get deviceAlerts => 'Device alerts';

  @override
  String get meditraceConnectionAndRefillAlerts =>
      'MEDITRACE connection and refill alerts';

  @override
  String get checkMeditraceContents => 'Check MEDITRACE contents';

  @override
  String get thisMorningMakeSureTheMedicationCompartmentsAre =>
      'This morning, make sure the medication compartments are filled for the next schedule.';

  @override
  String get meditraceIsMovingOutOfRange => 'MEDITRACE is moving out of range';

  @override
  String get meditraceSignalIsWeakMakeSureTheMedication =>
      'MEDITRACE signal is weak. Make sure the medication box is still with you.';

  @override
  String get meditraceNeedsARefill => 'MEDITRACE needs a refill';

  @override
  String get oneOrMoreMedicationCompartmentsAreEmpty =>
      'One or more medication compartments are empty.';

  @override
  String get meditraceAlarm => 'MEDITRACE alarm';

  @override
  String get medicationTaken3 => 'Medication taken';

  @override
  String get meditraceMedicationStatus => 'MEDITRACE medication status';

  @override
  String get meditraceFamilyAlert => 'MEDITRACE family alert';

  @override
  String get alertsFromMeditraceFamilyMembers =>
      'Alerts from MEDITRACE family members';

  @override
  String get medicationInTheBox => 'Medication in the box';

  @override
  String get connectMeditraceToSeeEachCompartmentSStatus =>
      'Connect MEDITRACE to see each compartment\'s status.';

  @override
  String get theSensorsCouldNotBeReadCheckThe =>
      'The sensors could not be read. Check the PCF8575 and try reading the sensors again.';

  @override
  String get gettingSensorStatusFromMeditrace =>
      'Getting sensor status from MEDITRACE...';

  @override
  String get notReadYet => 'Not read yet';

  @override
  String get medicationAvailable => 'Medication available';

  @override
  String get noMedication => 'No medication';

  @override
  String compartment3(String arg0) {
    return 'Compartment $arg0';
  }

  @override
  String get filled => 'Filled';

  @override
  String get empty => 'Empty';

  @override
  String get doorSensorUnavailable => 'Door sensor unavailable';

  @override
  String get closed => 'Closed';

  @override
  String get open => 'Open';

  @override
  String compartment4(String arg0) {
    return 'Compartment $arg0';
  }

  @override
  String medication(String arg0) {
    return 'Medication: $arg0';
  }

  @override
  String door(String arg0) {
    return 'Door: $arg0';
  }

  @override
  String members(String arg0) {
    return '$arg0 members';
  }

  @override
  String get appPhone => 'App/phone';

  @override
  String get age => 'Age';

  @override
  String get exampleBudi => 'Example: Budi';

  @override
  String get example => 'Example: 08123456789';

  @override
  String get hr => '< 1 hr';

  @override
  String get apkDownloadFailed => 'Could not download the latest APK.';

  @override
  String get appUpdatePageFailed => 'Could not open the app update page.';

  @override
  String get googleClientNotConfigured =>
      'GOOGLE_WEB_CLIENT_ID is missing. Complete the Firebase and OAuth configuration.';

  @override
  String get googleTokenMissing => 'Google did not return an ID token.';

  @override
  String googleSignInFailed(String arg0) {
    return 'Google sign-in failed: $arg0';
  }

  @override
  String firebaseSignInFailed(String arg0) {
    return 'Firebase sign-in failed: $arg0';
  }

  @override
  String get signOutNeedsInternet =>
      'Connect to the internet to stop notifications on this phone before signing out safely.';

  @override
  String get familyBackendInactive =>
      'The family backend is not active yet. Group and push features will be available later.';

  @override
  String get familyBackendRequiresHttps => 'The family backend must use HTTPS.';

  @override
  String get invalidBackendResponse => 'Invalid backend response.';

  @override
  String backendFailed(String arg0) {
    return 'Backend request failed ($arg0).';
  }

  @override
  String get familyBackendTimeout => 'The family backend did not respond.';

  @override
  String get familyBackendUnreachable =>
      'Could not connect to the family backend.';

  @override
  String get firebaseNotConfigured =>
      'Firebase is not configured. Set FIREBASE_* and rebuild the app.';

  @override
  String get googleSignInRequired => 'Please sign in with Google.';

  @override
  String firmwareUnavailable(String arg0) {
    return 'Online firmware is unavailable ($arg0).';
  }

  @override
  String get onlineFirmwareEmpty => 'The online firmware file is empty.';

  @override
  String get invalidEsp32Firmware =>
      'The file is not valid ESP32 firmware; update canceled.';

  @override
  String get language => 'Language';

  @override
  String get languageSaveFailed =>
      'Could not save language preference. Try again.';

  @override
  String get activity => 'Activity';

  @override
  String get openProfile => 'Open profile';

  @override
  String get familyNotificationsLoadFailed =>
      'Could not load family notifications';

  @override
  String get familyNotificationsRetryDescription =>
      'Check your connection and try again. Your local history is still available.';

  @override
  String get retry => 'Try again';

  @override
  String get refreshFamilyNotifications => 'Refresh family notifications';

  @override
  String get alertNeedsAttention => 'Needs attention';

  @override
  String get alertHandled => 'Handled';

  @override
  String get alertAcknowledgeFailed =>
      'Could not acknowledge this alert. Please try again.';

  @override
  String get clearFamilyNotifications => 'Clear family notifications';

  @override
  String get clearFamilyNotificationsDescription =>
      'Remove all family notifications from your cloud inbox on this account? Other family members\' copies will stay.';

  @override
  String get deleteFamilyNotification => 'Delete family notification';

  @override
  String get deleteFamilyNotificationDescription =>
      'Remove this notification from your cloud inbox on this account? Other family members\' copies will stay.';

  @override
  String get alertDeleteFailed =>
      'Could not delete the notification. Please try again.';

  @override
  String get noActivityYet => 'No activity yet';

  @override
  String get activityEmptyDescription =>
      'Medication history, device events, and family notifications will appear here.';

  @override
  String get activityGuestDescription =>
      'Medication and device activity will appear here. Sign in from your profile to also receive family notifications.';

  @override
  String get localActivity => 'Device & medication';

  @override
  String get invitationAccepted => 'You have joined the family group.';

  @override
  String get invitationReviewDescription =>
      'Accept this invitation to join the family group. The code can only be used once.';

  @override
  String get invitationSignInDescription =>
      'Sign in using the profile card above, then accept this invitation. Your code will stay here.';
}
