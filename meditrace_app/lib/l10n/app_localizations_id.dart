// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get welcomeToMeditrace => 'Selamat datang di MEDITRACE';

  @override
  String get signInToUseFamilyFeaturesAndAccount =>
      'Masuk untuk menggunakan fitur keluarga dan sinkronisasi akun, atau lanjut sebagai tamu untuk memakai fitur lokal.';

  @override
  String get continueAsGuest => 'Lanjut sebagai tamu';

  @override
  String get signIn => 'Login';

  @override
  String get meditraceUser => 'Pengguna MEDITRACE';

  @override
  String get myFamily => 'Keluarga Saya';

  @override
  String get medicationTakenBasedOnRemoval =>
      'Obat diminum berdasarkan pengambilan.';

  @override
  String get early => 'lebih awal';

  @override
  String get onTime => 'tepat waktu';

  @override
  String get late => 'terlambat';

  @override
  String medicationTaken(String arg0) {
    return 'Obat diminum $arg0.';
  }

  @override
  String get medicationStatusTaken => 'Status obat: sudah diminum';

  @override
  String medicationScheduledAsWasRecordedAsTaken(String arg0, String arg1) {
    return 'Obat pada jadwal $arg0 tercatat sudah diminum ($arg1).';
  }

  @override
  String get early2 => 'lebih cepat';

  @override
  String get recorded => 'tercatat';

  @override
  String get theFirmwareFileIsEmpty => 'File firmware kosong.';

  @override
  String compartmentIsEmpty(String arg0) {
    return 'Obat di kompartemen $arg0 kosong';
  }

  @override
  String meditraceDetectedThatCompartmentIsEmptyCheckAnd(String arg0) {
    return 'Sensor MEDITRACE mendeteksi kompartemen $arg0 kosong. Periksa dan isi ulang obat.';
  }

  @override
  String get meditraceDisconnectedFromPhone => 'MEDITRACE terputus dari HP';

  @override
  String get thePatientWasWarnedAfterSecondsMeditraceHas =>
      'Pasien telah diperingatkan setelah 30 detik. MEDITRACE belum terhubung kembali 5 menit kemudian. Periksa jarak dan daya perangkat.';

  @override
  String get patientReportedMeditraceLeftBehind =>
      'Pasien melaporkan MEDITRACE tertinggal';

  @override
  String get thePatientConfirmedThatTheMeditraceMedicationBox =>
      'Pasien mengonfirmasi bahwa kotak obat MEDITRACE tertinggal.';

  @override
  String get couldNotSendTheAlertCheckYourSign =>
      'Peringatan gagal dikirim. Periksa login dan grup keluarga.';

  @override
  String medicationInCompartmentWasRecordedAsTaken(String arg0, String arg1) {
    return 'Obat pada ruang $arg0 tercatat sudah diminum ($arg1).';
  }

  @override
  String compartment(String arg0) {
    return ' ruang $arg0';
  }

  @override
  String medicationScheduleCompartmentEmptyRefillFirst(String arg0) {
    return 'Jadwal obat$arg0: ruang kosong, isi ulang dulu.';
  }

  @override
  String timeToTakeMedication(String arg0) {
    return 'Waktunya minum obat$arg0.';
  }

  @override
  String get meditraceConnected => 'MEDITRACE terhubung';

  @override
  String get connectingToMeditrace => 'Menghubungkan MEDITRACE';

  @override
  String get meditraceNotConnected => 'MEDITRACE belum terhubung';

  @override
  String get pleaseWait => 'Mohon tunggu sebentar...';

  @override
  String get noMeditrace => 'Tidak ada MEDITRACE';

  @override
  String get refreshMeditraceStatus => 'Perbarui kondisi MEDITRACE';

  @override
  String get deviceDetails => 'Detail perangkat';

  @override
  String get batterySignalAndTechnicalInformation =>
      'Baterai, sinyal, dan informasi teknis';

  @override
  String get estimatedBattery => 'Estimasi baterai';

  @override
  String get battery => 'Baterai';

  @override
  String get estimatedRuntime => 'Estimasi durasi';

  @override
  String get estimatedFromAMahBatteryAndAnAverage =>
      'Perkiraan dari baterai 1500 mAh dan arus rata-rata 150 mA (sekitar 10 jam). Mulai dari asumsi penuh saat pertama digunakan. Setelah dicas penuh, tandai penuh di bawah. Pengisian daya tidak terdeteksi otomatis.';

  @override
  String get markBatteryAsFull => 'Tandai baterai penuh';

  @override
  String get signalStrength => 'Kuat sinyal';

  @override
  String get deviceId => 'ID perangkat';

  @override
  String get scheduleSource => 'Sumber jadwal';

  @override
  String get unsentEvents => 'Event belum dikirim';

  @override
  String get espCFirmware => 'Firmware ESP32-C3';

  @override
  String get theLatestUpdateIsDownloadedFromGithubReleases =>
      'Update terbaru diunduh dari GitHub Release lalu dikirim ke perangkat melalui BLE.';

  @override
  String get updateToLatestFirmware => 'Update firmware terbaru';

  @override
  String get chooseLocalBinFile => 'Pilih file .bin lokal';

  @override
  String sendingFirmware(String arg0) {
    return 'Mengirim firmware $arg0%...';
  }

  @override
  String get firmwareSentTheDeviceIsRestarting =>
      'Firmware selesai dikirim. Perangkat sedang restart.';

  @override
  String get findMeditrace => 'Cari MEDITRACE';

  @override
  String get disconnect => 'Putuskan koneksi';

  @override
  String get meditraceDevice => 'Perangkat MEDITRACE';

  @override
  String get isTheBatteryFullyCharged => 'Baterai sudah dicas penuh?';

  @override
  String get theEstimateWillRestartFromUseThisOnly =>
      'Estimasi akan dimulai lagi dari 100%. Gunakan hanya setelah baterai benar-benar dicas penuh.';

  @override
  String get cancel => 'Batal';

  @override
  String get markAsFull => 'Tandai penuh';

  @override
  String couldNotDownloadFirmware(String arg0) {
    return 'Gagal mengunduh firmware: $arg0';
  }

  @override
  String get updateFirmware => 'Update firmware?';

  @override
  String theDeviceWillRestartAfterTheUpdateBytes(String arg0) {
    return 'Perangkat akan restart setelah update selesai. $arg0 byte akan dikirim melalui BLE.';
  }

  @override
  String get disconnectMeditrace => 'Putuskan MEDITRACE?';

  @override
  String get afterDisconnectingMeditraceWillNotReconnectAutomaticallyYou =>
      'Setelah diputus, MEDITRACE tidak akan tersambung otomatis. Anda perlu menghubungkannya kembali secara manual.';

  @override
  String get stopScanning => 'Hentikan scan';

  @override
  String get scanAgain => 'Scan ulang';

  @override
  String get close => 'Tutup';

  @override
  String get noMeditraceFoundYetMakeSureTheMedication =>
      'Belum ada MEDITRACE ditemukan.\nPastikan kotak obat menyala, Bluetooth aktif, dan posisinya dekat dengan HP.';

  @override
  String get tapToConnect => 'Ketuk untuk menghubungkan';

  @override
  String get history => 'Riwayat';

  @override
  String get clearLocalHistory => 'Hapus riwayat lokal';

  @override
  String get noHistoryYet => 'Belum ada riwayat';

  @override
  String get medicationAndDeviceActivityWillAppearHere =>
      'Aktivitas obat dan perangkat akan muncul di sini.';

  @override
  String compartment2(String arg0) {
    return ' · Ruang $arg0';
  }

  @override
  String get clearAllHistory => 'Hapus semua riwayat?';

  @override
  String get allLocalActivityWillBeDeletedAndCannot =>
      'Semua aktivitas lokal akan dihapus dan tidak dapat dipulihkan.';

  @override
  String get delete => 'Hapus';

  @override
  String get medicationRemoved => 'Obat diambil';

  @override
  String get compartmentFilled => 'Kompartemen terisi';

  @override
  String get compartmentEmpty => 'Kompartemen kosong';

  @override
  String get compartmentClosed => 'Kompartemen ditutup';

  @override
  String get compartmentOpened => 'Kompartemen dibuka';

  @override
  String get medicationReminder => 'Pengingat obat';

  @override
  String medicationTaken2(String arg0) {
    return 'Obat diminum · $arg0';
  }

  @override
  String get medicationConfirmationRevoked => 'Konfirmasi minum dibatalkan';

  @override
  String get medicationScheduleMissed => 'Jadwal obat terlewat';

  @override
  String get meditracePoweredBackOnAndConnected =>
      'MEDITRACE hidup kembali dan terhubung';

  @override
  String get meditracePoweredOnAndConnected => 'MEDITRACE hidup dan terhubung';

  @override
  String get meditraceConnectionLost => 'Koneksi MEDITRACE terputus';

  @override
  String get warningMeditraceNotDetected =>
      'Peringatan: MEDITRACE tidak terdeteksi';

  @override
  String get alertSentToFamily => 'Peringatan dikirim ke keluarga';

  @override
  String get meditraceReconnected => 'MEDITRACE terhubung kembali';

  @override
  String get meditraceReportedLeftBehind => 'MEDITRACE dilaporkan tertinggal';

  @override
  String get deviceActivity => 'Aktivitas perangkat';

  @override
  String get familyNotifications => 'Pemberitahuan keluarga';

  @override
  String get alertsForCaregiversAndFamilyMembers =>
      'Peringatan caregiver dan anggota keluarga';

  @override
  String get noFamilyNotificationsYet => 'Belum ada pemberitahuan keluarga';

  @override
  String get familyAlert => 'Peringatan keluarga';

  @override
  String get family => 'Keluarga';

  @override
  String get senderEmailUnavailable => 'Email pengirim tidak tersedia';

  @override
  String get acknowledge => 'Tangani';

  @override
  String get meditraceLogo => 'Logo MEDITRACE';

  @override
  String get home => 'Home';

  @override
  String get schedule => 'Jadwal';

  @override
  String get device => 'Perangkat';

  @override
  String get profile => 'Profil';

  @override
  String get connectMeditraceToRefreshItsStatus =>
      'Hubungkan MEDITRACE untuk memperbarui kondisi.';

  @override
  String get welcome => 'Selamat datang!';

  @override
  String get keepTrackOfYourMedicationScheduleToday =>
      'Pantau jadwal obatmu hari ini.';

  @override
  String get meditraceActive => 'MEDITRACE aktif';

  @override
  String get connectDevice => 'Hubungkan perangkat';

  @override
  String get estimatedFromUsageTimeRatherThanVoltageMeasurement =>
      'Perkiraan waktu pemakaian, bukan pengukuran tegangan.';

  @override
  String get weakSignal => 'Sinyal lemah';

  @override
  String get keepMeditraceNearby => 'Pastikan MEDITRACE tetap dekat.';

  @override
  String get nextSchedule => 'Jadwal berikutnya';

  @override
  String get noMedicationSchedulesYet => 'Belum ada jadwal obat';

  @override
  String get waitForTheNextMedicationSchedule =>
      'Tunggu jadwal obat berikutnya';

  @override
  String get medicationIsNotAvailableInThisCompartmentYet =>
      'Obat belum tersedia di kompartemen ini.';

  @override
  String get viewMedicationSchedule => 'Lihat jadwal obat';

  @override
  String get taken => 'Sudah minum';

  @override
  String get medicationBox => 'Kotak obat';

  @override
  String get viewAll => 'Lihat semua';

  @override
  String get compartmentStatus => 'Status kompartemen';

  @override
  String get complete => 'Lengkap';

  @override
  String get needsRefill => 'Perlu diisi';

  @override
  String ofCompartmentsFilled(String arg0, String arg1) {
    return '$arg0 dari $arg1 kompartemen terisi';
  }

  @override
  String get connectMeditraceToSeeContents =>
      'Hubungkan MEDITRACE untuk melihat isi';

  @override
  String get allCompartmentsAreFilled => 'Semua kompartemen sudah terisi.';

  @override
  String get refillMedicationBeforeTheNextSchedule =>
      'Isi obat sebelum jadwal berikutnya.';

  @override
  String get medicationSchedule => 'Jadwal Obat';

  @override
  String get addAReminderToAvoidMissingMedication =>
      'Tambahkan pengingat agar obat tidak terlewat.';

  @override
  String get addSchedule => 'Tambah jadwal';

  @override
  String get everyDay => 'Setiap hari';

  @override
  String get scheduleActions => 'Aksi jadwal';

  @override
  String get deleteSchedule => 'Hapus jadwal';

  @override
  String get takenTodayUndo => 'Sudah diminum hari ini · batalkan';

  @override
  String get deleteMedicationSchedule => 'Hapus jadwal obat?';

  @override
  String scheduleAtWillBeDeleted(String arg0, String arg1) {
    return 'Jadwal $arg0 pukul $arg1 akan dihapus.';
  }

  @override
  String get scheduleDeleted => 'Jadwal berhasil dihapus.';

  @override
  String get haveYouTakenTheMedication => 'Obat sudah diminum?';

  @override
  String get revokeConfirmation => 'Batalkan konfirmasi?';

  @override
  String get confirmOnlyIfTheMedicationFromThisCompartment =>
      'Konfirmasi hanya jika obat dari ruang ini benar-benar sudah diminum, bukan sekadar diambil dari kotak.';

  @override
  String get todaySTakenStatusWillBeRevoked =>
      'Status diminum hari ini akan dibatalkan.';

  @override
  String get back => 'Kembali';

  @override
  String get yesTaken => 'Ya, sudah diminum';

  @override
  String get revokeStatus => 'Batalkan status';

  @override
  String get medicationSchedule2 => 'Jadwal obat';

  @override
  String get scheduleAdded => 'Jadwal berhasil ditambahkan.';

  @override
  String get scheduleUpdated => 'Jadwal berhasil diperbarui.';

  @override
  String get save => 'Simpan';

  @override
  String get caregiverInvitationCode => 'Kode undangan caregiver';

  @override
  String get validForDaysAndCanOnlyBeUsed =>
      'Berlaku 7 hari dan hanya bisa dipakai sekali.';

  @override
  String get codeCopied => 'Kode berhasil disalin';

  @override
  String get copyCode => 'Salin kode';

  @override
  String get sendViaEmail => 'Kirim via email';

  @override
  String get sendInvitationViaEmail => 'Kirim undangan via email';

  @override
  String get recipientEmail => 'Email penerima';

  @override
  String get sendEmail => 'Kirim email';

  @override
  String get enterAValidEmailAddress => 'Masukkan alamat email yang valid.';

  @override
  String get editFamilyName => 'Edit nama keluarga';

  @override
  String get familyName => 'Nama keluarga';

  @override
  String get deleteFamilyGroup => 'Hapus grup keluarga?';

  @override
  String groupWillBeDeletedAndMembersWillLose(String arg0) {
    return 'Grup \"$arg0\" akan dihapus dan anggota tidak dapat lagi mengaksesnya. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get signInUsingTheProfileCardAboveTo =>
      'Masuk dari kartu Profil di atas untuk mengatur grup dan berbagi peringatan dengan keluarga.';

  @override
  String get signInWithGoogle => 'Masuk dengan Google';

  @override
  String get accountConnected => 'Akun sudah terhubung';

  @override
  String get signOut => 'Keluar';

  @override
  String get groupSettingsAreNotActiveYet => 'Pengaturan grup belum aktif';

  @override
  String get localFeaturesRemainAvailableConnectTheBackendTo =>
      'Fitur lokal tetap berjalan. Hubungkan backend untuk mengatur keluarga.';

  @override
  String get familyGroups => 'Grup keluarga';

  @override
  String get alertsForEmptyCompartmentsAndMeditraceDisconnectionsAre =>
      'Peringatan ruang obat kosong dan MEDITRACE terputus dikirim ke grup yang Anda miliki. Koneksi manual yang diputus tidak mengirim peringatan.';

  @override
  String get familyAlertsActive => 'Peringatan keluarga aktif';

  @override
  String get meditraceWillSendAlertsToYourFamilyGroup =>
      'MEDITRACE akan mengirim peringatan ke grup keluarga Anda.';

  @override
  String get inviteCaregiver => 'Undang caregiver';

  @override
  String get editName => 'Edit nama';

  @override
  String get deleteGroup => 'Hapus grup';

  @override
  String get user => 'Pengguna';

  @override
  String get emailNotRegisteredYet => 'Email belum terdaftar';

  @override
  String get owner => 'Pemilik';

  @override
  String get createGroup => 'Buat grup';

  @override
  String get createFamilyGroup => 'Buat grup keluarga';

  @override
  String get joinGroup => 'Gabung grup';

  @override
  String get invitationCode => 'Kode undangan';

  @override
  String get enterInvitationCode => 'Masukkan kode undangan';

  @override
  String get invalidFamilyGroupId => 'ID grup keluarga tidak valid.';

  @override
  String get medicationUsageGuide => 'Panduan penggunaan obat';

  @override
  String get importantNote => 'Catatan penting';

  @override
  String get thisIsGeneralInformationAndDoesNotReplace =>
      'Informasi ini bersifat umum dan tidak menggantikan instruksi dokter, apoteker, maupun etiket obat Anda.';

  @override
  String get whyDoesSchedulingMatter => 'Mengapa jadwal penting?';

  @override
  String get takingMedicationRegularlyAccordingToYourTreatmentPlan =>
      'Minum obat secara teratur sesuai rencana terapi membantu obat bekerja sebagaimana yang diharapkan. Gunakan pengingat MEDITRACE sebagai pendamping, lalu ikuti aturan pada resep.';

  @override
  String get doNotChangeTheDoseYourself => 'Jangan mengubah dosis sendiri';

  @override
  String get skippingDelayingOrTakingDosesTooCloseTogether =>
      'Melewatkan, menunda, atau meminum dosis terlalu berdekatan dapat mengurangi manfaat obat atau meningkatkan risiko efek samping. Jangan menghentikan, menambah, atau menggandakan dosis tanpa arahan dokter atau apoteker.';

  @override
  String get ifYouForgetADose => 'Kalau lupa minum obat';

  @override
  String get instructionsVaryBetweenMedicationsCheckTheLabelOr =>
      'Aturannya tidak sama untuk semua obat. Periksa etiket atau leaflet obat dan hubungi dokter atau apoteker bila ragu. Jangan langsung menggandakan dosis untuk mengganti yang lupa.';

  @override
  String get practicalGuide => 'Panduan praktis';

  @override
  String get fillCompartmentsAccordingToThePrescriptionAndOriginal =>
      '• Isi kompartemen sesuai resep dan label asli obat.\n• Tekan “Sudah minum” setelah obat benar-benar diminum atau digunakan sesuai instruksi.\n• Catat atau tanyakan bila ada efek yang mengganggu.\n• Jangan menghancurkan atau membuka kapsul tanpa petunjuk tenaga kesehatan.';

  @override
  String get whenDoYouNeedUrgentHelp => 'Kapan perlu bantuan segera?';

  @override
  String get contactLocalEmergencyServicesImmediatelyIfYouDevelop =>
      'Segera hubungi layanan gawat darurat setempat bila setelah obat muncul sulit bernapas atau bengkak pada wajah, bibir, mulut, atau tenggorokan. Untuk keluhan lain yang mengkhawatirkan, hubungi dokter atau apoteker.';

  @override
  String get referenceNhsGuidanceOnDelayedDosesMedicationManagement =>
      'Rujukan: panduan layanan NHS tentang keterlambatan dosis, pengelolaan obat, dan penggunaan obat oleh pendamping.';

  @override
  String get familyInvitation => 'Undangan keluarga';

  @override
  String invitationCodeIsReadyToUse(String arg0) {
    return 'Kode undangan $arg0 sudah siap digunakan.';
  }

  @override
  String get later => 'Nanti';

  @override
  String get joinNow => 'Gabung sekarang';

  @override
  String enterCodeInTheFamilySection(String arg0) {
    return 'Masukkan kode $arg0 di bagian Keluarga';
  }

  @override
  String get accountEmailUnavailable => 'Email akun tidak tersedia';

  @override
  String get notSignedIn => 'Belum masuk';

  @override
  String get completeProfile => 'Lengkapi profil';

  @override
  String get signOutOfAccount => 'Keluar dari akun';

  @override
  String get healthInformation => 'Data kesehatan';

  @override
  String get patientInformationAndEmergencyContacts =>
      'Informasi pasien dan kontak darurat';

  @override
  String get ageNotProvided => 'Umur belum diisi';

  @override
  String ageYears(String arg0) {
    return 'Umur $arg0 tahun';
  }

  @override
  String get emergencyContactNotProvided => 'Kontak darurat belum diisi';

  @override
  String get emergencyContactSaved => 'Kontak darurat sudah tersimpan';

  @override
  String get updateApp => 'Perbarui aplikasi';

  @override
  String get downloadTheLatestMeditraceApkFromGithubReleases =>
      'Unduh APK terbaru MEDITRACE dari GitHub Release.';

  @override
  String get manageGroupsCaregiversAndNotifications =>
      'Atur grup, caregiver, dan pemberitahuan';

  @override
  String get signInToConnectWithFamily => 'Masuk untuk menghubungkan keluarga';

  @override
  String get reminderWhenMeditraceIsLeftBehind =>
      'Pengingat saat MEDITRACE tertinggal';

  @override
  String get thePatientIsWarnedSecondsAfterDisconnectionIf =>
      'Pasien diperingatkan 30 detik setelah terputus. Jika belum reconnect 5 menit kemudian, caregiver diberi tahu.';

  @override
  String get alertSavedButTheCaregiverEmailCouldNot =>
      'Peringatan tersimpan, tetapi email caregiver gagal dikirim.';

  @override
  String alertSentToCaregiverEmailAddresses(String arg0) {
    return 'Peringatan dikirim ke $arg0 email caregiver.';
  }

  @override
  String get alertSavedAndBeingProcessedForTheCaregiver =>
      'Peringatan tersimpan dan sedang diproses untuk caregiver.';

  @override
  String get iLeftMeditraceBehind => 'Saya meninggalkan MEDITRACE';

  @override
  String get editProfile => 'Ubah profil';

  @override
  String get userName => 'Nama pengguna';

  @override
  String get exampleBudiSFamily => 'Contoh: Keluarga Budi';

  @override
  String get emergencyPhoneNumber => 'Nomor darurat';

  @override
  String get emergencyEmail => 'Email darurat';

  @override
  String get notAvailableYet => 'Belum tersedia';

  @override
  String hrMin(String arg0, String arg1) {
    return '$arg0 jam $arg1 menit';
  }

  @override
  String get alertsFromCaregiversAndFamilyMembers =>
      'Peringatan dari caregiver dan anggota keluarga';

  @override
  String get timeToTakeMedication2 => 'Waktunya minum obat';

  @override
  String openMeditraceNow(String arg0, String arg1) {
    return '$arg0 • $arg1. Buka MEDITRACE sekarang.';
  }

  @override
  String checkCompartment(String arg0, String arg1, String arg2) {
    return '$arg0 • $arg1. Periksa ruang $arg2.';
  }

  @override
  String get dailyMeditraceMedicationReminders =>
      'Pengingat jadwal obat harian MEDITRACE';

  @override
  String get meditraceNotDetected => 'MEDITRACE tidak terdeteksi';

  @override
  String get makeSureTheMedicationBoxHasNotBeen =>
      'Pastikan kotak obat tidak tertinggal.';

  @override
  String get deviceAlerts => 'Peringatan perangkat';

  @override
  String get meditraceConnectionAndRefillAlerts =>
      'Peringatan koneksi dan isi ulang MEDITRACE';

  @override
  String get checkMeditraceContents => 'Periksa isi MEDITRACE';

  @override
  String get thisMorningMakeSureTheMedicationCompartmentsAre =>
      'Pagi ini, pastikan kompartemen obat telah terisi untuk jadwal berikutnya.';

  @override
  String get meditraceIsMovingOutOfRange => 'MEDITRACE mulai jauh';

  @override
  String get meditraceSignalIsWeakMakeSureTheMedication =>
      'Sinyal MEDITRACE lemah. Pastikan kotak obat masih bersama Anda.';

  @override
  String get meditraceNeedsARefill => 'MEDITRACE perlu diisi';

  @override
  String get oneOrMoreMedicationCompartmentsAreEmpty =>
      'Satu atau lebih ruang obat terdeteksi kosong.';

  @override
  String get meditraceAlarm => 'Alarm MEDITRACE';

  @override
  String get medicationTaken3 => 'Obat diminum';

  @override
  String get meditraceMedicationStatus => 'Status minum obat MEDITRACE';

  @override
  String get meditraceFamilyAlert => 'Peringatan keluarga MEDITRACE';

  @override
  String get alertsFromMeditraceFamilyMembers =>
      'Peringatan dari anggota keluarga MEDITRACE';

  @override
  String get medicationInTheBox => 'Obat di kotak';

  @override
  String get connectMeditraceToSeeEachCompartmentSStatus =>
      'Hubungkan MEDITRACE untuk melihat kondisi tiap ruang.';

  @override
  String get theSensorsCouldNotBeReadCheckThe =>
      'Sensor belum berhasil dibaca. Periksa PCF8575 dan coba Baca sensor lagi.';

  @override
  String get gettingSensorStatusFromMeditrace =>
      'Mengambil status sensor dari MEDITRACE...';

  @override
  String get notReadYet => 'Belum terbaca';

  @override
  String get medicationAvailable => 'Obat tersedia';

  @override
  String get noMedication => 'Obat kosong';

  @override
  String compartment3(String arg0) {
    return 'Ruang $arg0';
  }

  @override
  String get filled => 'Terisi';

  @override
  String get empty => 'Kosong';

  @override
  String get doorSensorUnavailable => 'Sensor pintu tidak tersedia';

  @override
  String get closed => 'Tertutup';

  @override
  String get open => 'Terbuka';

  @override
  String compartment4(String arg0) {
    return 'Kompartemen $arg0';
  }

  @override
  String medication(String arg0) {
    return 'Obat: $arg0';
  }

  @override
  String door(String arg0) {
    return 'Pintu: $arg0';
  }

  @override
  String members(String arg0) {
    return '$arg0 anggota';
  }

  @override
  String get appPhone => 'Aplikasi/ponsel';

  @override
  String get age => 'Umur';

  @override
  String get exampleBudi => 'Contoh: Budi';

  @override
  String get example => 'Contoh: 08123456789';

  @override
  String get hr => '< 1 jam';

  @override
  String get apkDownloadFailed => 'APK terbaru tidak dapat diunduh.';

  @override
  String get appUpdatePageFailed =>
      'Halaman update aplikasi tidak dapat dibuka.';

  @override
  String get googleClientNotConfigured =>
      'GOOGLE_WEB_CLIENT_ID belum diisi. Lengkapi konfigurasi Firebase dan OAuth.';

  @override
  String get googleTokenMissing => 'Google tidak mengirim ID token.';

  @override
  String googleSignInFailed(String arg0) {
    return 'Login Google gagal: $arg0';
  }

  @override
  String firebaseSignInFailed(String arg0) {
    return 'Login Firebase gagal: $arg0';
  }

  @override
  String get signOutNeedsInternet =>
      'Untuk keluar dengan aman, hubungkan internet agar notifikasi HP ini dihentikan dahulu.';

  @override
  String get familyBackendInactive =>
      'Backend keluarga belum aktif. Fitur grup dan push menyusul.';

  @override
  String get familyBackendRequiresHttps =>
      'Backend keluarga harus memakai HTTPS.';

  @override
  String get invalidBackendResponse => 'Balasan backend tidak valid.';

  @override
  String backendFailed(String arg0) {
    return 'Backend gagal ($arg0).';
  }

  @override
  String get familyBackendTimeout => 'Backend keluarga tidak merespons.';

  @override
  String get familyBackendUnreachable =>
      'Tidak dapat menghubungi backend keluarga.';

  @override
  String get firebaseNotConfigured =>
      'Firebase belum dikonfigurasi. Isi FIREBASE_* lalu build ulang aplikasi.';

  @override
  String get googleSignInRequired => 'Silakan masuk dengan Google.';

  @override
  String firmwareUnavailable(String arg0) {
    return 'Firmware online tidak tersedia ($arg0).';
  }

  @override
  String get onlineFirmwareEmpty => 'File firmware online kosong.';

  @override
  String get invalidEsp32Firmware =>
      'File bukan firmware ESP32 yang valid; update dibatalkan.';

  @override
  String get language => 'Bahasa';

  @override
  String get languageSaveFailed => 'Gagal menyimpan pilihan bahasa. Coba lagi.';

  @override
  String get activity => 'Aktivitas';

  @override
  String get openProfile => 'Buka profil';

  @override
  String get familyNotificationsLoadFailed =>
      'Pemberitahuan keluarga belum dapat dimuat';

  @override
  String get familyNotificationsRetryDescription =>
      'Periksa koneksi lalu coba lagi. Riwayat lokal tetap tersedia.';

  @override
  String get retry => 'Coba lagi';

  @override
  String get refreshFamilyNotifications => 'Segarkan pemberitahuan keluarga';

  @override
  String get alertNeedsAttention => 'Perlu ditangani';

  @override
  String get alertHandled => 'Sudah ditangani';

  @override
  String get alertAcknowledgeFailed =>
      'Peringatan belum berhasil ditangani. Silakan coba lagi.';

  @override
  String get noActivityYet => 'Belum ada aktivitas';

  @override
  String get activityEmptyDescription =>
      'Riwayat obat, aktivitas perangkat, dan pemberitahuan keluarga akan muncul di sini.';

  @override
  String get activityGuestDescription =>
      'Aktivitas obat dan perangkat akan muncul di sini. Masuk melalui profil untuk menerima pemberitahuan keluarga juga.';

  @override
  String get localActivity => 'Perangkat & obat';

  @override
  String get invitationAccepted => 'Anda berhasil bergabung ke grup keluarga.';

  @override
  String get invitationReviewDescription =>
      'Terima undangan ini untuk bergabung ke grup keluarga. Kode hanya dapat digunakan sekali.';

  @override
  String get invitationSignInDescription =>
      'Masuk melalui kartu profil di atas, lalu terima undangan ini. Kode Anda tetap tersimpan di sini.';
}
