import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @welcomeToMeditrace.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MEDITRACE'**
  String get welcomeToMeditrace;

  /// No description provided for @signInToUseFamilyFeaturesAndAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use family features and account sync, or continue as a guest to use local features.'**
  String get signInToUseFamilyFeaturesAndAccount;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @meditraceUser.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE User'**
  String get meditraceUser;

  /// No description provided for @myFamily.
  ///
  /// In en, this message translates to:
  /// **'My Family'**
  String get myFamily;

  /// No description provided for @medicationTakenBasedOnRemoval.
  ///
  /// In en, this message translates to:
  /// **'Medication taken based on removal.'**
  String get medicationTakenBasedOnRemoval;

  /// No description provided for @early.
  ///
  /// In en, this message translates to:
  /// **'early'**
  String get early;

  /// No description provided for @onTime.
  ///
  /// In en, this message translates to:
  /// **'on time'**
  String get onTime;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'late'**
  String get late;

  /// No description provided for @medicationTaken.
  ///
  /// In en, this message translates to:
  /// **'Medication taken {arg0}.'**
  String medicationTaken(String arg0);

  /// No description provided for @medicationStatusTaken.
  ///
  /// In en, this message translates to:
  /// **'Medication status: taken'**
  String get medicationStatusTaken;

  /// No description provided for @medicationScheduledAsWasRecordedAsTaken.
  ///
  /// In en, this message translates to:
  /// **'Medication scheduled as {arg0} was recorded as taken ({arg1}).'**
  String medicationScheduledAsWasRecordedAsTaken(String arg0, String arg1);

  /// No description provided for @early2.
  ///
  /// In en, this message translates to:
  /// **'early'**
  String get early2;

  /// No description provided for @recorded.
  ///
  /// In en, this message translates to:
  /// **'recorded'**
  String get recorded;

  /// No description provided for @theFirmwareFileIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'The firmware file is empty.'**
  String get theFirmwareFileIsEmpty;

  /// No description provided for @compartmentIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Compartment {arg0} is empty'**
  String compartmentIsEmpty(String arg0);

  /// No description provided for @meditraceDetectedThatCompartmentIsEmptyCheckAnd.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE detected that compartment {arg0} is empty. Check and refill the medication.'**
  String meditraceDetectedThatCompartmentIsEmptyCheckAnd(String arg0);

  /// No description provided for @meditraceDisconnectedFromPhone.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE disconnected from phone'**
  String get meditraceDisconnectedFromPhone;

  /// No description provided for @thePatientWasWarnedAfterSecondsMeditraceHas.
  ///
  /// In en, this message translates to:
  /// **'The patient was warned after 30 seconds. MEDITRACE has not reconnected 5 minutes later. Check the device distance and power.'**
  String get thePatientWasWarnedAfterSecondsMeditraceHas;

  /// No description provided for @patientReportedMeditraceLeftBehind.
  ///
  /// In en, this message translates to:
  /// **'Patient reported MEDITRACE left behind'**
  String get patientReportedMeditraceLeftBehind;

  /// No description provided for @thePatientConfirmedThatTheMeditraceMedicationBox.
  ///
  /// In en, this message translates to:
  /// **'The patient confirmed that the MEDITRACE medication box was left behind.'**
  String get thePatientConfirmedThatTheMeditraceMedicationBox;

  /// No description provided for @couldNotSendTheAlertCheckYourSign.
  ///
  /// In en, this message translates to:
  /// **'Could not send the alert. Check your sign-in and family group.'**
  String get couldNotSendTheAlertCheckYourSign;

  /// No description provided for @medicationInCompartmentWasRecordedAsTaken.
  ///
  /// In en, this message translates to:
  /// **'Medication in compartment {arg0} was recorded as taken ({arg1}).'**
  String medicationInCompartmentWasRecordedAsTaken(String arg0, String arg1);

  /// No description provided for @compartment.
  ///
  /// In en, this message translates to:
  /// **' compartment {arg0}'**
  String compartment(String arg0);

  /// No description provided for @medicationScheduleCompartmentEmptyRefillFirst.
  ///
  /// In en, this message translates to:
  /// **'Medication schedule{arg0}: compartment empty, refill first.'**
  String medicationScheduleCompartmentEmptyRefillFirst(String arg0);

  /// No description provided for @timeToTakeMedication.
  ///
  /// In en, this message translates to:
  /// **'Time to take medication{arg0}.'**
  String timeToTakeMedication(String arg0);

  /// No description provided for @meditraceConnected.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE connected'**
  String get meditraceConnected;

  /// No description provided for @connectingToMeditrace.
  ///
  /// In en, this message translates to:
  /// **'Connecting to MEDITRACE'**
  String get connectingToMeditrace;

  /// No description provided for @meditraceNotConnected.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE not connected'**
  String get meditraceNotConnected;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @noMeditrace.
  ///
  /// In en, this message translates to:
  /// **'No MEDITRACE'**
  String get noMeditrace;

  /// No description provided for @refreshMeditraceStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh MEDITRACE status'**
  String get refreshMeditraceStatus;

  /// No description provided for @deviceDetails.
  ///
  /// In en, this message translates to:
  /// **'Device details'**
  String get deviceDetails;

  /// No description provided for @batterySignalAndTechnicalInformation.
  ///
  /// In en, this message translates to:
  /// **'Battery, signal, and technical information'**
  String get batterySignalAndTechnicalInformation;

  /// No description provided for @estimatedBattery.
  ///
  /// In en, this message translates to:
  /// **'Estimated battery'**
  String get estimatedBattery;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @estimatedRuntime.
  ///
  /// In en, this message translates to:
  /// **'Estimated runtime'**
  String get estimatedRuntime;

  /// No description provided for @estimatedFromAMahBatteryAndAnAverage.
  ///
  /// In en, this message translates to:
  /// **'Estimated from a 1500 mAh battery and an average current of 150 mA (about 10 hours). Assumes a full battery on first use. After fully charging, mark it as full below. Charging is not detected automatically.'**
  String get estimatedFromAMahBatteryAndAnAverage;

  /// No description provided for @markBatteryAsFull.
  ///
  /// In en, this message translates to:
  /// **'Mark battery as full'**
  String get markBatteryAsFull;

  /// No description provided for @signalStrength.
  ///
  /// In en, this message translates to:
  /// **'Signal strength'**
  String get signalStrength;

  /// No description provided for @deviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceId;

  /// No description provided for @scheduleSource.
  ///
  /// In en, this message translates to:
  /// **'Schedule source'**
  String get scheduleSource;

  /// No description provided for @unsentEvents.
  ///
  /// In en, this message translates to:
  /// **'Unsent events'**
  String get unsentEvents;

  /// No description provided for @espCFirmware.
  ///
  /// In en, this message translates to:
  /// **'ESP32-C3 firmware'**
  String get espCFirmware;

  /// No description provided for @theLatestUpdateIsDownloadedFromGithubReleases.
  ///
  /// In en, this message translates to:
  /// **'The latest update is downloaded from GitHub Releases and sent to the device over BLE.'**
  String get theLatestUpdateIsDownloadedFromGithubReleases;

  /// No description provided for @updateToLatestFirmware.
  ///
  /// In en, this message translates to:
  /// **'Update to latest firmware'**
  String get updateToLatestFirmware;

  /// No description provided for @chooseLocalBinFile.
  ///
  /// In en, this message translates to:
  /// **'Choose local .bin file'**
  String get chooseLocalBinFile;

  /// No description provided for @sendingFirmware.
  ///
  /// In en, this message translates to:
  /// **'Sending firmware {arg0}%...'**
  String sendingFirmware(String arg0);

  /// No description provided for @firmwareSentTheDeviceIsRestarting.
  ///
  /// In en, this message translates to:
  /// **'Firmware sent. The device is restarting.'**
  String get firmwareSentTheDeviceIsRestarting;

  /// No description provided for @findMeditrace.
  ///
  /// In en, this message translates to:
  /// **'Find MEDITRACE'**
  String get findMeditrace;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @meditraceDevice.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE device'**
  String get meditraceDevice;

  /// No description provided for @isTheBatteryFullyCharged.
  ///
  /// In en, this message translates to:
  /// **'Is the battery fully charged?'**
  String get isTheBatteryFullyCharged;

  /// No description provided for @theEstimateWillRestartFromUseThisOnly.
  ///
  /// In en, this message translates to:
  /// **'The estimate will restart from 100%. Use this only after the battery is fully charged.'**
  String get theEstimateWillRestartFromUseThisOnly;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @markAsFull.
  ///
  /// In en, this message translates to:
  /// **'Mark as full'**
  String get markAsFull;

  /// No description provided for @couldNotDownloadFirmware.
  ///
  /// In en, this message translates to:
  /// **'Could not download firmware: {arg0}'**
  String couldNotDownloadFirmware(String arg0);

  /// No description provided for @updateFirmware.
  ///
  /// In en, this message translates to:
  /// **'Update firmware?'**
  String get updateFirmware;

  /// No description provided for @theDeviceWillRestartAfterTheUpdateBytes.
  ///
  /// In en, this message translates to:
  /// **'The device will restart after the update. {arg0} bytes will be sent over BLE.'**
  String theDeviceWillRestartAfterTheUpdateBytes(String arg0);

  /// No description provided for @disconnectMeditrace.
  ///
  /// In en, this message translates to:
  /// **'Disconnect MEDITRACE?'**
  String get disconnectMeditrace;

  /// No description provided for @afterDisconnectingMeditraceWillNotReconnectAutomaticallyYou.
  ///
  /// In en, this message translates to:
  /// **'After disconnecting, MEDITRACE will not reconnect automatically. You will need to connect it again manually.'**
  String get afterDisconnectingMeditraceWillNotReconnectAutomaticallyYou;

  /// No description provided for @stopScanning.
  ///
  /// In en, this message translates to:
  /// **'Stop scanning'**
  String get stopScanning;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanAgain;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @noMeditraceFoundYetMakeSureTheMedication.
  ///
  /// In en, this message translates to:
  /// **'No MEDITRACE found yet.\nMake sure the medication box is powered on, Bluetooth is enabled, and it is close to your phone.'**
  String get noMeditraceFoundYetMakeSureTheMedication;

  /// No description provided for @tapToConnect.
  ///
  /// In en, this message translates to:
  /// **'Tap to connect'**
  String get tapToConnect;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @clearLocalHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear local history'**
  String get clearLocalHistory;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// No description provided for @medicationAndDeviceActivityWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Medication and device activity will appear here.'**
  String get medicationAndDeviceActivityWillAppearHere;

  /// No description provided for @compartment2.
  ///
  /// In en, this message translates to:
  /// **' · Compartment {arg0}'**
  String compartment2(String arg0);

  /// No description provided for @clearAllHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear all history?'**
  String get clearAllHistory;

  /// No description provided for @allLocalActivityWillBeDeletedAndCannot.
  ///
  /// In en, this message translates to:
  /// **'All local activity will be deleted and cannot be recovered.'**
  String get allLocalActivityWillBeDeletedAndCannot;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @medicationRemoved.
  ///
  /// In en, this message translates to:
  /// **'Medication removed'**
  String get medicationRemoved;

  /// No description provided for @compartmentFilled.
  ///
  /// In en, this message translates to:
  /// **'Compartment filled'**
  String get compartmentFilled;

  /// No description provided for @compartmentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Compartment empty'**
  String get compartmentEmpty;

  /// No description provided for @compartmentClosed.
  ///
  /// In en, this message translates to:
  /// **'Compartment closed'**
  String get compartmentClosed;

  /// No description provided for @compartmentOpened.
  ///
  /// In en, this message translates to:
  /// **'Compartment opened'**
  String get compartmentOpened;

  /// No description provided for @medicationReminder.
  ///
  /// In en, this message translates to:
  /// **'Medication reminder'**
  String get medicationReminder;

  /// No description provided for @medicationTaken2.
  ///
  /// In en, this message translates to:
  /// **'Medication taken · {arg0}'**
  String medicationTaken2(String arg0);

  /// No description provided for @medicationConfirmationRevoked.
  ///
  /// In en, this message translates to:
  /// **'Medication confirmation revoked'**
  String get medicationConfirmationRevoked;

  /// No description provided for @medicationScheduleMissed.
  ///
  /// In en, this message translates to:
  /// **'Medication schedule missed'**
  String get medicationScheduleMissed;

  /// No description provided for @meditracePoweredBackOnAndConnected.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE powered back on and connected'**
  String get meditracePoweredBackOnAndConnected;

  /// No description provided for @meditracePoweredOnAndConnected.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE powered on and connected'**
  String get meditracePoweredOnAndConnected;

  /// No description provided for @meditraceConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE connection lost'**
  String get meditraceConnectionLost;

  /// No description provided for @warningMeditraceNotDetected.
  ///
  /// In en, this message translates to:
  /// **'Warning: MEDITRACE not detected'**
  String get warningMeditraceNotDetected;

  /// No description provided for @alertSentToFamily.
  ///
  /// In en, this message translates to:
  /// **'Alert sent to family'**
  String get alertSentToFamily;

  /// No description provided for @meditraceReconnected.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE reconnected'**
  String get meditraceReconnected;

  /// No description provided for @meditraceReportedLeftBehind.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE reported left behind'**
  String get meditraceReportedLeftBehind;

  /// No description provided for @deviceActivity.
  ///
  /// In en, this message translates to:
  /// **'Device activity'**
  String get deviceActivity;

  /// No description provided for @familyNotifications.
  ///
  /// In en, this message translates to:
  /// **'Family notifications'**
  String get familyNotifications;

  /// No description provided for @alertsForCaregiversAndFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'Alerts for caregivers and family members'**
  String get alertsForCaregiversAndFamilyMembers;

  /// No description provided for @noFamilyNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No family notifications yet'**
  String get noFamilyNotificationsYet;

  /// No description provided for @familyAlert.
  ///
  /// In en, this message translates to:
  /// **'Family alert'**
  String get familyAlert;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @senderEmailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sender email unavailable'**
  String get senderEmailUnavailable;

  /// No description provided for @acknowledge.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get acknowledge;

  /// No description provided for @meditraceLogo.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE logo'**
  String get meditraceLogo;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @connectMeditraceToRefreshItsStatus.
  ///
  /// In en, this message translates to:
  /// **'Connect MEDITRACE to refresh its status.'**
  String get connectMeditraceToRefreshItsStatus;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @keepTrackOfYourMedicationScheduleToday.
  ///
  /// In en, this message translates to:
  /// **'Keep track of your medication schedule today.'**
  String get keepTrackOfYourMedicationScheduleToday;

  /// No description provided for @meditraceActive.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE active'**
  String get meditraceActive;

  /// No description provided for @connectDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect device'**
  String get connectDevice;

  /// No description provided for @estimatedFromUsageTimeRatherThanVoltageMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Estimated from usage time, rather than voltage measurement.'**
  String get estimatedFromUsageTimeRatherThanVoltageMeasurement;

  /// No description provided for @weakSignal.
  ///
  /// In en, this message translates to:
  /// **'Weak signal'**
  String get weakSignal;

  /// No description provided for @keepMeditraceNearby.
  ///
  /// In en, this message translates to:
  /// **'Keep MEDITRACE nearby.'**
  String get keepMeditraceNearby;

  /// No description provided for @nextSchedule.
  ///
  /// In en, this message translates to:
  /// **'Next schedule'**
  String get nextSchedule;

  /// No description provided for @noMedicationSchedulesYet.
  ///
  /// In en, this message translates to:
  /// **'No medication schedules yet'**
  String get noMedicationSchedulesYet;

  /// No description provided for @waitForTheNextMedicationSchedule.
  ///
  /// In en, this message translates to:
  /// **'Wait for the next medication schedule'**
  String get waitForTheNextMedicationSchedule;

  /// No description provided for @medicationIsNotAvailableInThisCompartmentYet.
  ///
  /// In en, this message translates to:
  /// **'Medication is not available in this compartment yet.'**
  String get medicationIsNotAvailableInThisCompartmentYet;

  /// No description provided for @viewMedicationSchedule.
  ///
  /// In en, this message translates to:
  /// **'View medication schedule'**
  String get viewMedicationSchedule;

  /// No description provided for @taken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get taken;

  /// No description provided for @medicationBox.
  ///
  /// In en, this message translates to:
  /// **'Medication box'**
  String get medicationBox;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @compartmentStatus.
  ///
  /// In en, this message translates to:
  /// **'Compartment status'**
  String get compartmentStatus;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @needsRefill.
  ///
  /// In en, this message translates to:
  /// **'Needs refill'**
  String get needsRefill;

  /// No description provided for @ofCompartmentsFilled.
  ///
  /// In en, this message translates to:
  /// **'{arg0} of {arg1} compartments filled'**
  String ofCompartmentsFilled(String arg0, String arg1);

  /// No description provided for @connectMeditraceToSeeContents.
  ///
  /// In en, this message translates to:
  /// **'Connect MEDITRACE to see contents'**
  String get connectMeditraceToSeeContents;

  /// No description provided for @allCompartmentsAreFilled.
  ///
  /// In en, this message translates to:
  /// **'All compartments are filled.'**
  String get allCompartmentsAreFilled;

  /// No description provided for @refillMedicationBeforeTheNextSchedule.
  ///
  /// In en, this message translates to:
  /// **'Refill medication before the next schedule.'**
  String get refillMedicationBeforeTheNextSchedule;

  /// No description provided for @medicationSchedule.
  ///
  /// In en, this message translates to:
  /// **'Medication Schedule'**
  String get medicationSchedule;

  /// No description provided for @addAReminderToAvoidMissingMedication.
  ///
  /// In en, this message translates to:
  /// **'Add a reminder to avoid missing medication.'**
  String get addAReminderToAvoidMissingMedication;

  /// No description provided for @addSchedule.
  ///
  /// In en, this message translates to:
  /// **'Add schedule'**
  String get addSchedule;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @scheduleActions.
  ///
  /// In en, this message translates to:
  /// **'Schedule actions'**
  String get scheduleActions;

  /// No description provided for @deleteSchedule.
  ///
  /// In en, this message translates to:
  /// **'Delete schedule'**
  String get deleteSchedule;

  /// No description provided for @takenTodayUndo.
  ///
  /// In en, this message translates to:
  /// **'Taken today · undo'**
  String get takenTodayUndo;

  /// No description provided for @deleteMedicationSchedule.
  ///
  /// In en, this message translates to:
  /// **'Delete medication schedule?'**
  String get deleteMedicationSchedule;

  /// No description provided for @scheduleAtWillBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Schedule {arg0} at {arg1} will be deleted.'**
  String scheduleAtWillBeDeleted(String arg0, String arg1);

  /// No description provided for @scheduleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Schedule deleted.'**
  String get scheduleDeleted;

  /// No description provided for @haveYouTakenTheMedication.
  ///
  /// In en, this message translates to:
  /// **'Have you taken the medication?'**
  String get haveYouTakenTheMedication;

  /// No description provided for @revokeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Revoke confirmation?'**
  String get revokeConfirmation;

  /// No description provided for @confirmOnlyIfTheMedicationFromThisCompartment.
  ///
  /// In en, this message translates to:
  /// **'Confirm only if the medication from this compartment has actually been taken, rather than simply removed from the box.'**
  String get confirmOnlyIfTheMedicationFromThisCompartment;

  /// No description provided for @todaySTakenStatusWillBeRevoked.
  ///
  /// In en, this message translates to:
  /// **'Today\'s taken status will be revoked.'**
  String get todaySTakenStatusWillBeRevoked;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @yesTaken.
  ///
  /// In en, this message translates to:
  /// **'Yes, taken'**
  String get yesTaken;

  /// No description provided for @revokeStatus.
  ///
  /// In en, this message translates to:
  /// **'Revoke status'**
  String get revokeStatus;

  /// No description provided for @medicationSchedule2.
  ///
  /// In en, this message translates to:
  /// **'Medication schedule'**
  String get medicationSchedule2;

  /// No description provided for @scheduleAdded.
  ///
  /// In en, this message translates to:
  /// **'Schedule added.'**
  String get scheduleAdded;

  /// No description provided for @scheduleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Schedule updated.'**
  String get scheduleUpdated;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @caregiverInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Caregiver invitation code'**
  String get caregiverInvitationCode;

  /// No description provided for @validForDaysAndCanOnlyBeUsed.
  ///
  /// In en, this message translates to:
  /// **'Valid for 7 days and can only be used once.'**
  String get validForDaysAndCanOnlyBeUsed;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @sendViaEmail.
  ///
  /// In en, this message translates to:
  /// **'Send via email'**
  String get sendViaEmail;

  /// No description provided for @sendInvitationViaEmail.
  ///
  /// In en, this message translates to:
  /// **'Send invitation via email'**
  String get sendInvitationViaEmail;

  /// No description provided for @recipientEmail.
  ///
  /// In en, this message translates to:
  /// **'Recipient email'**
  String get recipientEmail;

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send email'**
  String get sendEmail;

  /// No description provided for @enterAValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get enterAValidEmailAddress;

  /// No description provided for @editFamilyName.
  ///
  /// In en, this message translates to:
  /// **'Edit family name'**
  String get editFamilyName;

  /// No description provided for @familyName.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get familyName;

  /// No description provided for @deleteFamilyGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete family group?'**
  String get deleteFamilyGroup;

  /// No description provided for @groupWillBeDeletedAndMembersWillLose.
  ///
  /// In en, this message translates to:
  /// **'Group \"{arg0}\" will be deleted and members will lose access. This action cannot be undone.'**
  String groupWillBeDeletedAndMembersWillLose(String arg0);

  /// No description provided for @signInUsingTheProfileCardAboveTo.
  ///
  /// In en, this message translates to:
  /// **'Sign in using the Profile card above to manage groups and share alerts with your family.'**
  String get signInUsingTheProfileCardAboveTo;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @accountConnected.
  ///
  /// In en, this message translates to:
  /// **'Account connected'**
  String get accountConnected;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @groupSettingsAreNotActiveYet.
  ///
  /// In en, this message translates to:
  /// **'Group settings are not active yet'**
  String get groupSettingsAreNotActiveYet;

  /// No description provided for @localFeaturesRemainAvailableConnectTheBackendTo.
  ///
  /// In en, this message translates to:
  /// **'Local features remain available. Connect the backend to manage your family.'**
  String get localFeaturesRemainAvailableConnectTheBackendTo;

  /// No description provided for @familyGroups.
  ///
  /// In en, this message translates to:
  /// **'Family groups'**
  String get familyGroups;

  /// No description provided for @alertsForEmptyCompartmentsAndMeditraceDisconnectionsAre.
  ///
  /// In en, this message translates to:
  /// **'Alerts for empty compartments and MEDITRACE disconnections are sent to groups you own. Manual disconnections do not send alerts.'**
  String get alertsForEmptyCompartmentsAndMeditraceDisconnectionsAre;

  /// No description provided for @familyAlertsActive.
  ///
  /// In en, this message translates to:
  /// **'Family alerts active'**
  String get familyAlertsActive;

  /// No description provided for @meditraceWillSendAlertsToYourFamilyGroup.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE will send alerts to your family group.'**
  String get meditraceWillSendAlertsToYourFamilyGroup;

  /// No description provided for @inviteCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Invite caregiver'**
  String get inviteCaregiver;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editName;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @emailNotRegisteredYet.
  ///
  /// In en, this message translates to:
  /// **'Email not registered yet'**
  String get emailNotRegisteredYet;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroup;

  /// No description provided for @createFamilyGroup.
  ///
  /// In en, this message translates to:
  /// **'Create family group'**
  String get createFamilyGroup;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join group'**
  String get joinGroup;

  /// No description provided for @invitationCode.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get invitationCode;

  /// No description provided for @enterInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter invitation code'**
  String get enterInvitationCode;

  /// No description provided for @invalidFamilyGroupId.
  ///
  /// In en, this message translates to:
  /// **'Invalid family group ID.'**
  String get invalidFamilyGroupId;

  /// No description provided for @medicationUsageGuide.
  ///
  /// In en, this message translates to:
  /// **'Medication usage guide'**
  String get medicationUsageGuide;

  /// No description provided for @importantNote.
  ///
  /// In en, this message translates to:
  /// **'Important note'**
  String get importantNote;

  /// No description provided for @thisIsGeneralInformationAndDoesNotReplace.
  ///
  /// In en, this message translates to:
  /// **'This is general information and does not replace instructions from your doctor, pharmacist, or medication label.'**
  String get thisIsGeneralInformationAndDoesNotReplace;

  /// No description provided for @whyDoesSchedulingMatter.
  ///
  /// In en, this message translates to:
  /// **'Why does scheduling matter?'**
  String get whyDoesSchedulingMatter;

  /// No description provided for @takingMedicationRegularlyAccordingToYourTreatmentPlan.
  ///
  /// In en, this message translates to:
  /// **'Taking medication regularly according to your treatment plan helps it work as intended. Use MEDITRACE reminders for support and follow your prescription instructions.'**
  String get takingMedicationRegularlyAccordingToYourTreatmentPlan;

  /// No description provided for @doNotChangeTheDoseYourself.
  ///
  /// In en, this message translates to:
  /// **'Do not change the dose yourself'**
  String get doNotChangeTheDoseYourself;

  /// No description provided for @skippingDelayingOrTakingDosesTooCloseTogether.
  ///
  /// In en, this message translates to:
  /// **'Skipping, delaying, or taking doses too close together can reduce benefits or increase the risk of side effects. Do not stop, increase, or double a dose without guidance from your doctor or pharmacist.'**
  String get skippingDelayingOrTakingDosesTooCloseTogether;

  /// No description provided for @ifYouForgetADose.
  ///
  /// In en, this message translates to:
  /// **'If you forget a dose'**
  String get ifYouForgetADose;

  /// No description provided for @instructionsVaryBetweenMedicationsCheckTheLabelOr.
  ///
  /// In en, this message translates to:
  /// **'Instructions vary between medications. Check the label or leaflet and contact your doctor or pharmacist if unsure. Do not automatically double a dose to make up for a missed one.'**
  String get instructionsVaryBetweenMedicationsCheckTheLabelOr;

  /// No description provided for @practicalGuide.
  ///
  /// In en, this message translates to:
  /// **'Practical guide'**
  String get practicalGuide;

  /// No description provided for @fillCompartmentsAccordingToThePrescriptionAndOriginal.
  ///
  /// In en, this message translates to:
  /// **'• Fill compartments according to the prescription and original medication label.\n• Tap “Taken” after the medication has actually been taken or used as instructed.\n• Record or ask about any bothersome effects.\n• Do not crush tablets or open capsules without guidance from a healthcare professional.'**
  String get fillCompartmentsAccordingToThePrescriptionAndOriginal;

  /// No description provided for @whenDoYouNeedUrgentHelp.
  ///
  /// In en, this message translates to:
  /// **'When do you need urgent help?'**
  String get whenDoYouNeedUrgentHelp;

  /// No description provided for @contactLocalEmergencyServicesImmediatelyIfYouDevelop.
  ///
  /// In en, this message translates to:
  /// **'Contact local emergency services immediately if you develop difficulty breathing or swelling of the face, lips, mouth, or throat after taking medication. For other concerning symptoms, contact your doctor or pharmacist.'**
  String get contactLocalEmergencyServicesImmediatelyIfYouDevelop;

  /// No description provided for @referenceNhsGuidanceOnDelayedDosesMedicationManagement.
  ///
  /// In en, this message translates to:
  /// **'Reference: NHS guidance on delayed doses, medication management, and supporting someone with their medication.'**
  String get referenceNhsGuidanceOnDelayedDosesMedicationManagement;

  /// No description provided for @familyInvitation.
  ///
  /// In en, this message translates to:
  /// **'Family invitation'**
  String get familyInvitation;

  /// No description provided for @invitationCodeIsReadyToUse.
  ///
  /// In en, this message translates to:
  /// **'Invitation code {arg0} is ready to use.'**
  String invitationCodeIsReadyToUse(String arg0);

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @joinNow.
  ///
  /// In en, this message translates to:
  /// **'Join now'**
  String get joinNow;

  /// No description provided for @enterCodeInTheFamilySection.
  ///
  /// In en, this message translates to:
  /// **'Enter code {arg0} in the Family section'**
  String enterCodeInTheFamilySection(String arg0);

  /// No description provided for @accountEmailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account email unavailable'**
  String get accountEmailUnavailable;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get completeProfile;

  /// No description provided for @signOutOfAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out of account'**
  String get signOutOfAccount;

  /// No description provided for @healthInformation.
  ///
  /// In en, this message translates to:
  /// **'Health information'**
  String get healthInformation;

  /// No description provided for @patientInformationAndEmergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Patient information and emergency contacts'**
  String get patientInformationAndEmergencyContacts;

  /// No description provided for @ageNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Age not provided'**
  String get ageNotProvided;

  /// No description provided for @ageYears.
  ///
  /// In en, this message translates to:
  /// **'Age {arg0} years'**
  String ageYears(String arg0);

  /// No description provided for @emergencyContactNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact not provided'**
  String get emergencyContactNotProvided;

  /// No description provided for @emergencyContactSaved.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact saved'**
  String get emergencyContactSaved;

  /// No description provided for @updateApp.
  ///
  /// In en, this message translates to:
  /// **'Update app'**
  String get updateApp;

  /// No description provided for @downloadTheLatestMeditraceApkFromGithubReleases.
  ///
  /// In en, this message translates to:
  /// **'Download the latest MEDITRACE APK from GitHub Releases.'**
  String get downloadTheLatestMeditraceApkFromGithubReleases;

  /// No description provided for @manageGroupsCaregiversAndNotifications.
  ///
  /// In en, this message translates to:
  /// **'Manage groups, caregivers, and notifications'**
  String get manageGroupsCaregiversAndNotifications;

  /// No description provided for @signInToConnectWithFamily.
  ///
  /// In en, this message translates to:
  /// **'Sign in to connect with family'**
  String get signInToConnectWithFamily;

  /// No description provided for @reminderWhenMeditraceIsLeftBehind.
  ///
  /// In en, this message translates to:
  /// **'Reminder when MEDITRACE is left behind'**
  String get reminderWhenMeditraceIsLeftBehind;

  /// No description provided for @thePatientIsWarnedSecondsAfterDisconnectionIf.
  ///
  /// In en, this message translates to:
  /// **'The patient is warned 30 seconds after disconnection. If it has not reconnected 5 minutes later, the caregiver is notified.'**
  String get thePatientIsWarnedSecondsAfterDisconnectionIf;

  /// No description provided for @alertSavedButTheCaregiverEmailCouldNot.
  ///
  /// In en, this message translates to:
  /// **'Alert saved, but the caregiver email could not be sent.'**
  String get alertSavedButTheCaregiverEmailCouldNot;

  /// No description provided for @alertSentToCaregiverEmailAddresses.
  ///
  /// In en, this message translates to:
  /// **'Alert sent to {arg0} caregiver email addresses.'**
  String alertSentToCaregiverEmailAddresses(String arg0);

  /// No description provided for @alertSavedAndBeingProcessedForTheCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Alert saved and being processed for the caregiver.'**
  String get alertSavedAndBeingProcessedForTheCaregiver;

  /// No description provided for @iLeftMeditraceBehind.
  ///
  /// In en, this message translates to:
  /// **'I left MEDITRACE behind'**
  String get iLeftMeditraceBehind;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'User name'**
  String get userName;

  /// No description provided for @exampleBudiSFamily.
  ///
  /// In en, this message translates to:
  /// **'Example: Budi\'s Family'**
  String get exampleBudiSFamily;

  /// No description provided for @emergencyPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Emergency phone number'**
  String get emergencyPhoneNumber;

  /// No description provided for @emergencyEmail.
  ///
  /// In en, this message translates to:
  /// **'Emergency email'**
  String get emergencyEmail;

  /// No description provided for @notAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get notAvailableYet;

  /// No description provided for @hrMin.
  ///
  /// In en, this message translates to:
  /// **'{arg0} hr {arg1} min'**
  String hrMin(String arg0, String arg1);

  /// No description provided for @alertsFromCaregiversAndFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'Alerts from caregivers and family members'**
  String get alertsFromCaregiversAndFamilyMembers;

  /// No description provided for @timeToTakeMedication2.
  ///
  /// In en, this message translates to:
  /// **'Time to take medication'**
  String get timeToTakeMedication2;

  /// No description provided for @openMeditraceNow.
  ///
  /// In en, this message translates to:
  /// **'{arg0} • {arg1}. Open MEDITRACE now.'**
  String openMeditraceNow(String arg0, String arg1);

  /// No description provided for @checkCompartment.
  ///
  /// In en, this message translates to:
  /// **'{arg0} • {arg1}. Check compartment {arg2}.'**
  String checkCompartment(String arg0, String arg1, String arg2);

  /// No description provided for @dailyMeditraceMedicationReminders.
  ///
  /// In en, this message translates to:
  /// **'Daily MEDITRACE medication reminders'**
  String get dailyMeditraceMedicationReminders;

  /// No description provided for @meditraceNotDetected.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE not detected'**
  String get meditraceNotDetected;

  /// No description provided for @makeSureTheMedicationBoxHasNotBeen.
  ///
  /// In en, this message translates to:
  /// **'Make sure the medication box has not been left behind.'**
  String get makeSureTheMedicationBoxHasNotBeen;

  /// No description provided for @deviceAlerts.
  ///
  /// In en, this message translates to:
  /// **'Device alerts'**
  String get deviceAlerts;

  /// No description provided for @meditraceConnectionAndRefillAlerts.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE connection and refill alerts'**
  String get meditraceConnectionAndRefillAlerts;

  /// No description provided for @checkMeditraceContents.
  ///
  /// In en, this message translates to:
  /// **'Check MEDITRACE contents'**
  String get checkMeditraceContents;

  /// No description provided for @thisMorningMakeSureTheMedicationCompartmentsAre.
  ///
  /// In en, this message translates to:
  /// **'This morning, make sure the medication compartments are filled for the next schedule.'**
  String get thisMorningMakeSureTheMedicationCompartmentsAre;

  /// No description provided for @meditraceIsMovingOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE is moving out of range'**
  String get meditraceIsMovingOutOfRange;

  /// No description provided for @meditraceSignalIsWeakMakeSureTheMedication.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE signal is weak. Make sure the medication box is still with you.'**
  String get meditraceSignalIsWeakMakeSureTheMedication;

  /// No description provided for @meditraceNeedsARefill.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE needs a refill'**
  String get meditraceNeedsARefill;

  /// No description provided for @oneOrMoreMedicationCompartmentsAreEmpty.
  ///
  /// In en, this message translates to:
  /// **'One or more medication compartments are empty.'**
  String get oneOrMoreMedicationCompartmentsAreEmpty;

  /// No description provided for @meditraceAlarm.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE alarm'**
  String get meditraceAlarm;

  /// No description provided for @medicationTaken3.
  ///
  /// In en, this message translates to:
  /// **'Medication taken'**
  String get medicationTaken3;

  /// No description provided for @meditraceMedicationStatus.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE medication status'**
  String get meditraceMedicationStatus;

  /// No description provided for @meditraceFamilyAlert.
  ///
  /// In en, this message translates to:
  /// **'MEDITRACE family alert'**
  String get meditraceFamilyAlert;

  /// No description provided for @alertsFromMeditraceFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'Alerts from MEDITRACE family members'**
  String get alertsFromMeditraceFamilyMembers;

  /// No description provided for @medicationInTheBox.
  ///
  /// In en, this message translates to:
  /// **'Medication in the box'**
  String get medicationInTheBox;

  /// No description provided for @connectMeditraceToSeeEachCompartmentSStatus.
  ///
  /// In en, this message translates to:
  /// **'Connect MEDITRACE to see each compartment\'s status.'**
  String get connectMeditraceToSeeEachCompartmentSStatus;

  /// No description provided for @theSensorsCouldNotBeReadCheckThe.
  ///
  /// In en, this message translates to:
  /// **'The sensors could not be read. Check the PCF8575 and try reading the sensors again.'**
  String get theSensorsCouldNotBeReadCheckThe;

  /// No description provided for @gettingSensorStatusFromMeditrace.
  ///
  /// In en, this message translates to:
  /// **'Getting sensor status from MEDITRACE...'**
  String get gettingSensorStatusFromMeditrace;

  /// No description provided for @notReadYet.
  ///
  /// In en, this message translates to:
  /// **'Not read yet'**
  String get notReadYet;

  /// No description provided for @medicationAvailable.
  ///
  /// In en, this message translates to:
  /// **'Medication available'**
  String get medicationAvailable;

  /// No description provided for @noMedication.
  ///
  /// In en, this message translates to:
  /// **'No medication'**
  String get noMedication;

  /// No description provided for @compartment3.
  ///
  /// In en, this message translates to:
  /// **'Compartment {arg0}'**
  String compartment3(String arg0);

  /// No description provided for @filled.
  ///
  /// In en, this message translates to:
  /// **'Filled'**
  String get filled;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @doorSensorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Door sensor unavailable'**
  String get doorSensorUnavailable;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @compartment4.
  ///
  /// In en, this message translates to:
  /// **'Compartment {arg0}'**
  String compartment4(String arg0);

  /// No description provided for @medication.
  ///
  /// In en, this message translates to:
  /// **'Medication: {arg0}'**
  String medication(String arg0);

  /// No description provided for @door.
  ///
  /// In en, this message translates to:
  /// **'Door: {arg0}'**
  String door(String arg0);

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'{arg0} members'**
  String members(String arg0);

  /// No description provided for @appPhone.
  ///
  /// In en, this message translates to:
  /// **'App/phone'**
  String get appPhone;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @exampleBudi.
  ///
  /// In en, this message translates to:
  /// **'Example: Budi'**
  String get exampleBudi;

  /// No description provided for @example.
  ///
  /// In en, this message translates to:
  /// **'Example: 08123456789'**
  String get example;

  /// No description provided for @hr.
  ///
  /// In en, this message translates to:
  /// **'< 1 hr'**
  String get hr;

  /// No description provided for @apkDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not download the latest APK.'**
  String get apkDownloadFailed;

  /// No description provided for @appUpdatePageFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the app update page.'**
  String get appUpdatePageFailed;

  /// No description provided for @googleClientNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'GOOGLE_WEB_CLIENT_ID is missing. Complete the Firebase and OAuth configuration.'**
  String get googleClientNotConfigured;

  /// No description provided for @googleTokenMissing.
  ///
  /// In en, this message translates to:
  /// **'Google did not return an ID token.'**
  String get googleTokenMissing;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: {arg0}'**
  String googleSignInFailed(String arg0);

  /// No description provided for @firebaseSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Firebase sign-in failed: {arg0}'**
  String firebaseSignInFailed(String arg0);

  /// No description provided for @signOutNeedsInternet.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to stop notifications on this phone before signing out safely.'**
  String get signOutNeedsInternet;

  /// No description provided for @familyBackendInactive.
  ///
  /// In en, this message translates to:
  /// **'The family backend is not active yet. Group and push features will be available later.'**
  String get familyBackendInactive;

  /// No description provided for @familyBackendRequiresHttps.
  ///
  /// In en, this message translates to:
  /// **'The family backend must use HTTPS.'**
  String get familyBackendRequiresHttps;

  /// No description provided for @invalidBackendResponse.
  ///
  /// In en, this message translates to:
  /// **'Invalid backend response.'**
  String get invalidBackendResponse;

  /// No description provided for @backendFailed.
  ///
  /// In en, this message translates to:
  /// **'Backend request failed ({arg0}).'**
  String backendFailed(String arg0);

  /// No description provided for @familyBackendTimeout.
  ///
  /// In en, this message translates to:
  /// **'The family backend did not respond.'**
  String get familyBackendTimeout;

  /// No description provided for @familyBackendUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the family backend.'**
  String get familyBackendUnreachable;

  /// No description provided for @firebaseNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Firebase is not configured. Set FIREBASE_* and rebuild the app.'**
  String get firebaseNotConfigured;

  /// No description provided for @googleSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in with Google.'**
  String get googleSignInRequired;

  /// No description provided for @firmwareUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Online firmware is unavailable ({arg0}).'**
  String firmwareUnavailable(String arg0);

  /// No description provided for @onlineFirmwareEmpty.
  ///
  /// In en, this message translates to:
  /// **'The online firmware file is empty.'**
  String get onlineFirmwareEmpty;

  /// No description provided for @invalidEsp32Firmware.
  ///
  /// In en, this message translates to:
  /// **'The file is not valid ESP32 firmware; update canceled.'**
  String get invalidEsp32Firmware;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save language preference. Try again.'**
  String get languageSaveFailed;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @openProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get openProfile;

  /// No description provided for @familyNotificationsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load family notifications'**
  String get familyNotificationsLoadFailed;

  /// No description provided for @familyNotificationsRetryDescription.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again. Your local history is still available.'**
  String get familyNotificationsRetryDescription;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @refreshFamilyNotifications.
  ///
  /// In en, this message translates to:
  /// **'Refresh family notifications'**
  String get refreshFamilyNotifications;

  /// No description provided for @alertNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get alertNeedsAttention;

  /// No description provided for @alertHandled.
  ///
  /// In en, this message translates to:
  /// **'Handled'**
  String get alertHandled;

  /// No description provided for @alertAcknowledgeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not acknowledge this alert. Please try again.'**
  String get alertAcknowledgeFailed;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivityYet;

  /// No description provided for @activityEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Medication history, device events, and family notifications will appear here.'**
  String get activityEmptyDescription;

  /// No description provided for @activityGuestDescription.
  ///
  /// In en, this message translates to:
  /// **'Medication and device activity will appear here. Sign in from your profile to also receive family notifications.'**
  String get activityGuestDescription;

  /// No description provided for @localActivity.
  ///
  /// In en, this message translates to:
  /// **'Device & medication'**
  String get localActivity;

  /// No description provided for @invitationAccepted.
  ///
  /// In en, this message translates to:
  /// **'You have joined the family group.'**
  String get invitationAccepted;

  /// No description provided for @invitationReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Accept this invitation to join the family group. The code can only be used once.'**
  String get invitationReviewDescription;

  /// No description provided for @invitationSignInDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in using the profile card above, then accept this invitation. Your code will stay here.'**
  String get invitationSignInDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
