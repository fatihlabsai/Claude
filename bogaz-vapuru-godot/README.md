# Boğaz Vapuru — Godot 4 sürümü

İstanbul Boğazı'nda bir Şehir Hatları vapurunun kaptanısın: Avrupa ile Asya arasında yolcu taşı, akıntıya ve büyük gemilere dikkat et, martılara simit at!

**Hemen oyna:** `index.html` dosyasını bir web sunucusundan aç (ör. `python3 -m http.server` ve ardından `http://localhost:8000`). Tek iş parçacıklı web dışa aktarımıdır; özel COOP/COEP başlığı gerekmez, GitHub Pages'te doğrudan çalışır.

## Nasıl oynanır

- **Hareket:** `W A S D` veya ok tuşları (ileri/geri, sola/sağa dönüş)
- **Simit at:** `Boşluk` — ya da fareyle suya tıkla, simit oraya uçar
- **Duraklat:** `P` veya `Esc` · **Menüde:** `Enter` seçili düğmeye basar
- **Dokunmatik:** sol alttaki joystick ile vapuru yönet, sağ alttaki **Simit At** düğmesine bas
- İskelelere (Karaköy, Beşiktaş, Kadıköy, Üsküdar) yanaş, yolcuları al ve gittikleri iskeleye bırak. Her seferde teslim hedefini süre bitmeden tamamla.
- Gemilere, kayıklara ve kıyıya çarpmak canını azaltır; martılara simit atmak bonus puan getirir. Akıntı yönü ve gücü HUD'da gösterilir.

## Projeyi Godot'da açmak

1. [Godot 4.7](https://godotengine.org/download) (standart sürüm) indir.
2. Godot Proje Yöneticisi → **İçe Aktar** → `project/project.godot` dosyasını seç.
3. **F5** ile çalıştır. Web için: **Proje → Dışa Aktar → Web** (hazır ayar, çıktıyı depo köküne `index.html` olarak yazar; Web dışa aktarım şablonları gerekir).

Komut satırından: `cd project && godot --headless --export-release "Web" ../index.html`

## Klasör yapısı

- `index.html`, `index.js`, `index.wasm`, `index.pck`, … — web dışa aktarımı
- `project/` — Godot proje kaynağı (`scripts/`, `shaders/`, `assets/`)
- `screenshots/` — ekran görüntüleri

## Emeği geçenler

Kullanılan tüm grafik, ses, müzik ve yazı tipleri ile lisansları: **[CREDITS.md](CREDITS.md)**
