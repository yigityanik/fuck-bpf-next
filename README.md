# LineageOS 24.0 için legacy kernel / BPF uyarlaması

Bu paket, techyminati/fuck-bpf `lineage-23.2` dalındaki değişiklikleri
LineageOS `lineage-24.0` kaynaklarına taşır. Her bileşen için birleştirilmiş
bir `git am` yaması içerir. Kaynak dal ile hedef revizyonlar
`BASE_REVISIONS.json` içinde sabitlenmiştir. Hazırlanma tarihi: 6 Ekim 2026.

## Kullanım

ZIP'i Android kaynak ağacının köküne çıkarın. Dizin adı
`fuck-bpf-lineage-24.0` olmalıdır. Kaynak ağacının kökünde:

```bash
bash fuck-bpf-lineage-24.0/apply.sh --check
bash fuck-bpf-lineage-24.0/apply.sh --mb
```

İlk komut tüm bileşenlerde uygulanabilirliği kontrol eder. İkinci komut
aynı kontrolü tekrar yapar ve sekiz Git deposuna yamaları commit olarak uygular.
Yerel değişiklik varsa işlemi durdurur; dosya silmez veya çalışma ağacını
sıfırlamaz. Git kullanıcı adı/e-posta ayarlarınızın mevcut olması gerekir.
Önceki 23.2 BPF yamaları uygulanmış bir ağaç yerine temiz 24.0 kaynakları kullanın.

## Uyarlanan noktalar

- Connectivity'nin `android::base::Result<void>` API'siyle uyumlu hata işleme.
- Android 17 kaynaklarındaki 25Q4/26Q4 kernel sürümü kontrollerinin gevşetilmesi.
- BPF program/map yükleme hatalarında platform loader ve `netbpfload done`
  akışının korunması; vendor yükleme hatasının açılışı beklemede bırakmaması.
- BpfNetMaps başlatma hatalarında süreç boyunca sabit fallback. Yeni izin chunk,
  yerel ağ cache/generation ve L4S işlemleri de bu durumda devre dışı kalır.
  Gerçek Android SDK kontrolleri korunur; sürüm sorguları sahte sonuç döndürmez.
- Yeni DNS başlatma akışında `ADnsHelper_init` hatasının abort yerine loglanması.
- Eski kernel için trafik istatistiklerinde qtaguid fallback'inin taşınması.
- Kaldırılan S/4.14 kernel config modülünün ve FCM 5/6 tanımlarının geri getirilmesi;
  FCM 5/6'nın her iki release modunda da kurulum listesine eklenmesi.
- Core cgroup ve APEX doğrudan I/O değişikliklerinin taşınması.

`frameworks/native` için yama yok: hedefte ilgili BLASTBufferQueue yolu zaten
`epoll_wait` ve milisaniye timeout dönüşümünü kullanıyor. S/4.19 gereksinimlerinin
bir kısmı da hedef kaynaklarda zaten gevşetilmişti.

## Doğrulama ve sınırlar

Sekiz bileşenin tamamına temiz, sabitlenmiş kaynaklarda `git am` uygulandı.
Ortaya çıkan Git tree hash'leri uyarlanmış kaynaklarla aynı. Değişen Java ve Rust
dosyalarında parser hatası yok; C++ dosyalarında standart format makroları
normalize edilerek önceki kaynaklara göre yeni parser hatası olmadığı kontrol edildi.
`git diff --check` geçti. Ayrıntılar `VALIDATION.json` dosyasında.

Bu doğrulamalar tam derleme veya cihaz testi değildir. ROM derlemesi, VINTF
uyumluluk denetimi ve cihazda açılış/ağ testleri yapılmadı. 4.4/4.9/4.14/4.19 için
kaynak uyumluluğu amaçlanır; bu pakette hiçbir cihaz/kernel kombinasyonu test edilmiş
olarak sunulmaz. Eski kaynak projenin 23.2 test sonuçları 24.0 için geçerli sayılmaz.

BPF fallback etkin olduğunda BPF tabanlı UID firewall, Data Saver, yerel ağ
erişim kontrolü, socket etiketleme ve bazı trafik muhasebesi özellikleri eksik
kalabilir. Trafik sayaçlarının qtaguid fallback'i için kernelde ilgili `/proc`
arayüzleri bulunmalıdır. HAL, blob, SELinux, device tree ve Android 17'nin BPF
dışındaki kernel gereksinimleri ayrıca ele alınmalıdır. FCM XML'lerinin geri
eklenmesi, tüm VINTF kontrollerinin geçtiği anlamına gelmez.

Hedef dallar ilerlediğinde `--check` başarısız olabilir; bu durumda
`BASE_REVISIONS.json` ile kaynak revizyonlarınızı karşılaştırın. Uygulama ortasında
Git hatası oluşursa önceki bileşenlerin commit'leri kalır; hata veren bileşende
`git am --continue` veya `git am --abort` kullanın.

## Kaynak ve lisans

Kaynak: https://github.com/techyminati/fuck-bpf/tree/lineage-23.2

Özgün yama yazarları ve commit konuları `SOURCES.md` içinde korunmuştur.
Paket Apache-2.0 lisanslı kaynak projeden türetilmiştir; `LICENSE` dosyasına bakın.

## FCM 5 config düzeltmesi

FCM 5'in kullandığı `kernel_config_r_5.4` modülü ve sekiz `r/android-5.4`
dosyası kernel/configs birleşik yamasına eklendi. Kaynak:
LineageOS/android_kernel_configs, `091688a5c5186cd124a0d19b06441bb8b04c3073`.
Bu değişiklik cihaz kernelini 5.4'e yükseltmez; matris bağımlılığını tamamlar.

Güncellenmiş paket temiz kaynak ağacı içindir. Önceki paket uygulanmışsa
tüm paketi yeniden uygulamayın; yalnızca eksik dosyaları geri getirin.

## FCM 6 HIDL düzeltmesi

FCM 6'da listelenip LineageOS 24.0 kaynaklarından kaldırılmış HIDL tanımları
hardware/interfaces birleşik yamasına geri eklendi:

- `android.hardware.automotive.sv@1.0`
- `android.hardware.dumpstate@1.1` ve bağımlılığı `@1.0`
- `android.hardware.input.classifier@1.0` ve bağımlılığı `input.common@1.0`
- `android.hardware.ir@1.0`

Kaynak: LineageOS/android_hardware_interfaces,
`13d687a84c834af855bfb314b853b8372a7aa6d9` (lineage-23.2).
Yalnızca doğrudan `Android.bp` ve `.hal` dosyaları eklenmiştir; servisler ve
testler dahil edilmemiştir. Bu değişiklik cihazda yeni HAL servisleri etkinleştirmez.
İki güncellenmiş yama temiz hedef revizyonlara `git am` ile doğrulanmıştır.
Tam ROM derlemesi ve cihaz testi yapılmamıştır.
