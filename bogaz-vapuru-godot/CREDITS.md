# Emeği Geçenler / Credits

Boğaz Vapuru (Godot 4 sürümü) için kullanılan tüm dış varlıklar aşağıdadır.
Hepsi **CC0** veya **CC-BY** (ve yazı tipleri için **SIL OFL 1.1**) lisanslıdır; ticari olmayan (NC) veya "yalnızca kişisel kullanım" lisanslı hiçbir varlık yoktur.
Lisanslar her kaynağın kendi sayfasında kontrol edilmiştir (Kasım 2026).

## Grafik

| Varlık | Yazar | Kaynak | Lisans | Kullanım |
|---|---|---|---|---|
| Pirate Pack — `dinghy_large_1-3.png` | Kenney (kenney.nl) | https://kenney.nl/assets/pirate-pack | CC0 1.0 | Kayık (sandal) gövdeleri |
| Pirate Pack — `rock_1-3.png` | Kenney | https://kenney.nl/assets/pirate-pack | CC0 1.0 | Kıyı kayalıkları, Kız Kulesi adacığı |
| Particle Pack — `smoke`, `soft`, `star`, `glow` (küçültüldü) | Kenney | https://kenney.nl/assets/particle-pack | CC0 1.0 | Baca dumanı, köpük/sıçrama, yıldız ve parıltı efektleri |
| UI Pack — `*_rectangle_depth_gloss.png` (sarı, mavi, gri, kırmızı, yeşil) | Kenney | https://kenney.nl/assets/ui-pack | CC0 1.0 | Menü ve HUD düğmeleri (arayüz teması) |

## Yazı tipleri

| Varlık | Yazar | Kaynak | Lisans | Kullanım |
|---|---|---|---|---|
| Baloo 2 (değişken, Latin + Latin-ext alt kümesi) | Ek Type | https://github.com/google/fonts/tree/main/ofl/baloo2 | SIL OFL 1.1 (`project/assets/fonts/OFL-Baloo2.txt`) | Başlıklar, düğmeler, HUD |
| Nunito (değişken, Latin + Latin-ext alt kümesi) | Vernon Adams, Cyreal, Jacques Le Bailly | https://github.com/google/fonts/tree/main/ofl/nunito | SIL OFL 1.1 (`project/assets/fonts/OFL-Nunito.txt`) | Gövde metinleri |

## Ses efektleri

| Varlık | Yazar | Kaynak | Lisans | Kullanım |
|---|---|---|---|---|
| Interface Sounds (`click`, `board`, `ding`, `bonus`, `sad`, `tick`, `toss`) | Kenney | https://kenney.nl/assets/interface-sounds | CC0 1.0 | Düğme, yolcu binişi/teslimi, bonus, süre uyarısı, simit atma |
| Impact Sounds (`hit_big`, `hit_small`, `bump`) | Kenney | https://kenney.nl/assets/impact-sounds | CC0 1.0 | Çarpışmalar, kıyıya sürtünme |
| Music Jingles (`win` = STEEL02, `lose` = STEEL01, `target` = PIZZI16) | Kenney | https://kenney.nl/assets/music-jingles | CC0 1.0 | Sefer tamamlandı, oyun bitti, hedef jingle'ı |
| Solo Seagull Sound Effects (`gull1-3`, `gull_happy`) | Rango Mango | https://opengameart.org/content/solo-seagull-sound-effects | CC0 1.0 | Martı sesleri, simit yakalayan martı |
| Ocean splash (`cannon_miss_0.ogg` → `splash`) | Thimras | https://opengameart.org/content/ocean-splash | CC0 1.0 | Simit suya düşünce sıçrama |
| Beach Ocean Waves (`wave`) | jasinski (yükleyen: qubodup) | https://opengameart.org/content/beach-ocean-waves | CC0 1.0 | Dalga/su çarpması |
| `horn`, `ship_horn` | Özgün (numpy ile sentezlendi, bu proje için) | — | Proje ile birlikte | Vapur düdüğü, gemi kornası |

## Müzik ve ortam sesi

| Varlık | Yazar | Kaynak | Lisans | Kullanım |
|---|---|---|---|---|
| "Merchants and Sea Salt" (`menu.ogg`) | NBJDLukasAbsolute | https://opengameart.org/content/merchants-and-sea-salt | CC0 1.0 | Menü müziği |
| "Mediterranean Breeze (Looping)" (`game.ogg`) | Eric Matyas — www.soundimage.org | https://opengameart.org/content/mediterranean-breezelooping | **CC-BY 3.0** | Oyun içi müzik |
| "Sea and river wave sounds" — VistulaShort'tan 46 sn'lik parça (`ambience.ogg`) | RandomMind | https://opengameart.org/content/sea-and-river-wave-sounds | CC0 1.0 | Sürekli deniz ortam sesi |

**CC-BY atfı:** "Mediterranean Breeze (Looping)" — Eric Matyas, www.soundimage.org, CC-BY 3.0 (https://creativecommons.org/licenses/by/3.0/). Dosya yalnızca OGG'ye dönüştürüldü, içerik değiştirilmedi. Atıf oyunun ana menüsünde de yer alır.

## Özgün içerik

Aşağıdakiler bu proje için sıfırdan yazıldı/çizildi (dış varlık değildir):

- Tüm GDScript kodu (`project/scripts/`) ve shader'lar (`project/shaders/`: su, gökyüzü, vinyet).
- Prosedürel çizimler: Şehir Hatları tarzı vapur, tanker ve kargo gemileri, martılar, simit, yolcular, bayraklar, kıyı şehri (evler, ağaçlar, Galata Kulesi, Dolmabahçe, Ortaköy, Haydarpaşa, Selimiye, Çamlıca, Kız Kulesi, Boğaz Köprüsü), paralaks silüet.
- Oyun simgesi (`project/icon.png`).
- Oynanış, orijinal HTML5 sürümünden (`bogaz-vapuru/index.html`) birebir aktarılmıştır.

Motor: [Godot Engine 4.7](https://godotengine.org) — MIT lisansı.
