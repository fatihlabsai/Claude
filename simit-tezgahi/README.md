# Boğaz'ın Simitçisi

Üsküdar sahilinde, simit tezgâhının arkasından İstanbul'a bakan birinci şahıs bir tarayıcı oyunu. Claude Fable 5.2 tarafından yazıldı.

**Durum (10 Kasım 2026, Europe/Istanbul):** 3B sahne, tezgâh ve ürünler görünür; **oyun döngüsü henüz yok.** Fable ikinci oturumda sahneyi, cart'ı, martıları, kedi Susam'ı ve hava efektlerini yazdı; müşteri / sipariş / ödeme / gün mantığına geçerken 5 saatlik limit doldu (yeniden **20:50 Europe/Istanbul**). Başlık ekranı sahnenin üstünde kalır ve “Tezgâh kuruluyor…”de takılır; “Güne Başla” henüz çalışmaz.

`index.html` içinde `//@@NEXT@@` işareti duruyor. Limit sıfırlanınca aynı oturum (`d89a5b12-a6de-45ea-894a-2fe87c785d70`) buradan devam ettirilebilir. İşaretten hemen sonra, sahnenin görünmesi için kısa bir geçici çizim döngüsü eklendi (oyun mantığı değil); Fable devam edince bunun yerine asıl döngü yazılmalı.

## Açmak

- Yerel: bir HTTP sunucusuyla açın (ör. `python3 -m http.server`). `file://` ile ES modülleri çalışmayabilir.
- GitHub Pages: https://fatihlabsai.github.io/fable-5-2-simit-tezgahi/

## Planlanan oynanış (kodlanmayı bekliyor)

Müşteri gelince sipariş fişte görünür; ürünlere tıklayarak/dokunarak tepsiye dizilir, **Servis Et** ile verilir, para üstü banknotlarla doğru hesaplanır. Hızlı ve doğru servis bahşiş ve esnaf itibarı kazandırır; sabrı biten müşteri gider. Gün ilerler, zorluk artar, gün sonunda özet çıkar.

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

### Müşteri tipleri (verisi ve 3B figür kurucusu var, gelme/sipariş yok)

Öğrenci, beyaz yakalı, teyze, turist, balıkçı, çocuk, taksici, vapur yolcusu, sokak müzisyeni, taraftar; ayrıca düzenli müşteri **Hasan Amca**, **zabıta** ve **askıda simit** isteyen bir yolcu. Sahilde geçen yayalar ve olta tutan balıkçılar görünür.

## Fable'ın yorumu

- Üsküdar sahili bakışı: Tarihî Yarımada camileri, Galata Kulesi, Kız Kulesi, Boğaz Köprüsü, vapurlar, martı sürüsü
- Tezgâhta fiyat panosu, **askıda simit** tabelası, **ruhsat**, semaver, fırın zili, kasa, bahşiş kutusu, radyo
- Tezgâhın kedisi **Susam**
- Simit çalmaya çalışan bir **martı** (durum makinesi iskeleti var, oyun döngüsüne bağlanmadı)
- Yağmur ve çay/semaver buharı
- Pazarlık, bahşiş, esnaf itibarı, gün kaydı ve hicaz makamında radyo/saz (arayüz ve ses hazır; oynanış bağlı değil)
- Düzenli müşteri **Hasan Amca**, zabıta baskını, askıda simit

## Kontroller (planlanan)

Fare veya dokunma: ürün seç, tepsiyi düzelt, servis et, para üstü ver, semaver / fırın / ruhsat / radyo / martı / kedi ile etkileş. Boş yerden sürükleyerek sınırlı bakış. Ses ve mola düğmeleri HUD’da.

## Teknik

Tek dosya: `index.html`. Three.js r170 CDN import map. Geometri, doku ve ses prosedürel. Prompt: `PROMPT.txt`.

Üreten model: **Claude Fable 5.2**.
