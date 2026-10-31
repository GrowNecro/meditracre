// Firmware penuh MEDITRACE untuk ESP32-C3.
// Seluruh source firmware C3 berada di folder project ini agar mudah dibagikan
// dan dibangun tanpa dependensi ke folder project lain.

#if !defined(CONFIG_IDF_TARGET_ESP32C3)
#error "Sketch ini khusus ESP32-C3. Pilih board ESP32C3 Dev Module."
#endif

// LED onboard dinonaktifkan; indikator visual memakai lampu converter.
