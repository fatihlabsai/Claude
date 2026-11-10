# Claude

[Fatih Kol](https://github.com/fatihlabsai) tarafından **Claude Code** ile (Claude Fable 5.2 ve Claude Opus 5.5) üretilen tarayıcı projeleri.

Her klasör bağımsız bir projedir; commit geçmişi korunmuştur. Hepsi tek HTML dosyasında çalışır, derleme adımı yoktur. 3B projelerde Three.js CDN üzerinden yüklenir.

**Canlı site:** [fatihlabsai.github.io/Claude](https://fatihlabsai.github.io/Claude/)

## Projeler

| Klasör | Model | Açıklama | Durum | Oyna |
| --- | --- | --- | --- | --- |
| [`fable-city/`](./fable-city/) | Claude Fable 5.2 | Prosedürel düşük poligonlu 3B şehir. Trafik, yayalar, gece-gündüz döngüsü; herhangi bir arabaya tıklayıp sürebilirsiniz. | Tamamlandı | [Aç](https://fatihlabsai.github.io/Claude/fable-city/) |
| [`simit-tezgahi/`](./simit-tezgahi/) | Claude Fable 5.2 | *Boğaz'ın Simitçisi* — Üsküdar sahilinde, tezgâhın arkasından İstanbul'a bakan birinci şahıs simitçilik oyunu. | Devam ediyor: 3B sahne hazır, **oyun döngüsü henüz yazılmadı** | [Aç](https://fatihlabsai.github.io/Claude/simit-tezgahi/) |
| [`bogaz-vapuru/`](./bogaz-vapuru/) | Claude Opus 5.5 | *Boğaz Vapuru* — iskeleler arasında yolcu taşıdığın, tankerlerden ve akıntıdan kaçıp martılara simit attığın 2D Canvas oyunu. Klavye ve dokunmatik. | Tamamlandı | [Aç](https://fatihlabsai.github.io/Claude/bogaz-vapuru/) |

## Yerel olarak açmak

Bir HTTP sunucusu yeterlidir:

```bash
python3 -m http.server
```

Ardından [http://localhost:8000](http://localhost:8000), [fable-city](http://localhost:8000/fable-city/) , [simit-tezgahi](http://localhost:8000/simit-tezgahi/) veya [bogaz-vapuru](http://localhost:8000/bogaz-vapuru/) adreslerine gidin.
