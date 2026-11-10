# Claude

[Fatih Kol](https://github.com/fatihlabsai) tarafından **Claude Code** ve **Claude Fable 5.2** ile üretilen tarayıcı projeleri.

Her klasör bağımsız bir projedir; commit geçmişi korunmuştur. Hepsi tek HTML dosyasında çalışır, derleme adımı yoktur. Three.js CDN üzerinden yüklenir.

**Canlı site:** [fatihlabsai.github.io/Claude](https://fatihlabsai.github.io/Claude/)

## Projeler

| Klasör | Model | Açıklama | Durum | Oyna |
| --- | --- | --- | --- | --- |
| [`fable-city/`](./fable-city/) | Claude Fable 5.2 | Prosedürel düşük poligonlu 3B şehir. Trafik, yayalar, gece-gündüz döngüsü; herhangi bir arabaya tıklayıp sürebilirsiniz. | Tamamlandı | [Aç](https://fatihlabsai.github.io/Claude/fable-city/) |
| [`simit-tezgahi/`](./simit-tezgahi/) | Claude Fable 5.2 | *Boğaz'ın Simitçisi* — Üsküdar sahilinde, tezgâhın arkasından İstanbul'a bakan birinci şahıs simitçilik oyunu. | Devam ediyor: 3B sahne hazır, **oyun döngüsü henüz yazılmadı** | [Aç](https://fatihlabsai.github.io/Claude/simit-tezgahi/) |

## Yerel olarak açmak

Bir HTTP sunucusu yeterlidir:

```bash
python3 -m http.server
```

Ardından [http://localhost:8000](http://localhost:8000), [fable-city](http://localhost:8000/fable-city/) veya [simit-tezgahi](http://localhost:8000/simit-tezgahi/) adreslerine gidin.
