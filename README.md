# Boğaz'ın Simitçisi

Üsküdar sahilinde, simit tezgâhının arkasından İstanbul'a bakan birinci şahıs bir tarayıcı oyunu. Claude Fable 5.2 tarafından tek promptta yazılması planlandı.

**Durum (10 Kasım 2026, Europe/Istanbul):** Oyun **henüz oynanabilir değil.** Fable, HTML/CSS arayüzünü, ürün ve müşteri verisini ve prosedürel ses sistemini yazdıktan sonra (`index.html` içinde `//@@NEXT@@` işaretinde durdu) 5 saatlik Claude Code oturum limitine takıldı. 3B sahne (Boğaz, Galata, camiler, tezgâh, müşteriler) ve oyun döngüsü yazılamadı. Başlık ekranı açılır ve “Tezgâh kuruluyor…”de kalır; “Güne Başla” görünmez.

Limit **15:10 (Europe/Istanbul)** civarında sıfırlanınca aynı oturum (`d89a5b12-a6de-45ea-894a-2fe87c785d70`) `//@@NEXT@@` noktasından parça parça devam ettirilebilir.

## Açmak

- Yerel: bir HTTP sunucusuyla `index.html` dosyasını açın (ör. `python3 -m http.server`). `file://` ile ES modülleri çalışmayabilir.
- GitHub Pages: bu deponun Pages adresinden (eksik sürüm).

## Planlanan oynanış

Tezgâhın arkasından bakarsınız. Müşteri gelince sipariş fişte görünür; ürünlere tıklayarak/dokunarak tepsiye dizilir, **Servis Et** ile verilir, para üstü banknot ve bozulukla doğru hesaplanır. Hızlı ve doğru servis bahşiş ve esnaf itibarı kazandırır; sabrı biten müşteri gider. Gün ilerler, zorluk artar, gün sonunda özet çıkar.

### Ürünler (2026 sokak fiyatları, TL)

| Ürün | Fiyat | Stok tavanı |
| --- | ---: | ---: |
| Simit | 25 | 14 |
| Kaşarlı Simit | 50 | 8 |
| Açma | 30 | 8 |
| Poğaça | 30 | 8 |
| Çay | 20 | 6 |
| Ayran | 35 | 8 |
| Su | 15 | 8 |

### Müşteri tipleri (verisi yazıldı, 3B/yapay zekâ davranışı henüz yok)

Öğrenci, beyaz yakalı, teyze, turist, balıkçı, çocuk, taksici, vapur yolcusu, sokak müzisyeni, taraftar; ayrıca düzenli müşteri **Hasan Amca**, **zabıta** ve **askıda simit** isteyen bir yolcu.

## Fable'ın yorumu

Fable bunları veri, arayüz ve yardım metnine işledi; sahne ve mekanikler kodlanamadı:

- Düzenli müşteri **Hasan Amca** — her sabah aynı sipariş (bir simit, bir çay)
- **Askıda simit** (bir yolcu gelir, askıda simit sorar; kayıtta sayaç vardır)
- **Zabıta** baskını — ruhsata dokunulması planlandı
- Tezgâhın kedisi **Susam** (sevince mırıldanır)
- **Martı** simit çalmaya çalışır; kovulması gerekir
- **Semaver** ve **fırın zili** ile stok yenileme (çay / hamur işi bitince)
- Pazarlık diyalogları, bahşiş, esnaf itibarı (yıldızlar)
- Gün kaydı (`localStorage`), artan zorluk
- Vapur düdüğü, yağmur, martı ve kedi sesleri; **hicaz makamında** radyo / saz (Web Audio ile sentetik)
- Üsküdar sahili bakış açısı: Tarihî Yarımada, Galata Kulesi, vapurlar

## Kontroller (planlanan)

Fare veya dokunma: ürün seç, tepsiyi düzelt, servis et, para üstü ver, semaver / fırın / ruhsat / radyo / martı / kedi ile etkileş. Boş yerden sürükleyerek sınırlı bakış. Ses ve mola düğmeleri HUD’da.

## Teknik

Tek dosya: `index.html`. Three.js r170 CDN import map ile yüklenecek şekilde bırakıldı; tüm geometri, doku ve ses prosedürel olacaktı. Dış varlık yok.

Bu depodaki `index.html`, limit kesintisi anındaki ilk parça yazımdır (~535 satır). Prompt: `PROMPT.txt`.

Üreten model: **Claude Fable 5.2**.
