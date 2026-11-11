## Title menu, pause, settings, help, credits, death and victory screens.
extends Control

var game: Node
var current := ""
var rects := {}
var _box: Control

func setup(g: Node) -> void:
	game = g
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _clear() -> void:
	for c in get_children():
		c.queue_free()
	rects.clear()

func _panel(title: String, dim := 0.45) -> VBoxContainer:
	_clear()
	visible = true
	var bg := ColorRect.new(); bg.color = Color(0.1, 0.05, 0.02, dim)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var pc := PanelContainer.new()
	add_child(pc)
	_box = pc
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	pc.add_child(v)
	if title != "":
		var t := UiKit.label(title, 40, UiKit.INK, true)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(t)
	_center.call_deferred(pc)
	return v

func _center(pc: Control) -> void:
	await get_tree().process_frame
	if not is_instance_valid(pc):
		return
	var vs := get_viewport_rect().size
	pc.position = ((vs - pc.size) / 2).max(Vector2(6, 6))
	for b in pc.find_children("*", "Button", true, false):
		rects[b.text] = Rect2(b.global_position, b.size)

func _btn(v: Container, text: String, cb: Callable, w := 320.0) -> Button:
	var b := UiKit.button(text, cb, 26, w)
	b.custom_minimum_size.y = 58
	v.add_child(b)
	return b

func hide_all() -> void:
	_clear()
	visible = false
	current = ""

func show_title() -> void:
	current = "title"
	var v := _panel("", 0.0)
	var t := UiKit.label("Çölde", 56, Color("#e2683c"), true, 0)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var t2 := UiKit.label("Hayatta Kalma", 46, UiKit.INK, true)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.add_theme_constant_override("line_spacing", -20)
	v.add_child(t2)
	var sub := UiKit.label("Uçağın düştü. Su bul, gölgede kal, geceyi ateşle geçir.", 18, Color("#6b4a2b"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size.x = 320
	v.add_child(sub)
	if game.has_save():
		var info: Dictionary = game.save_info()
		_btn(v, "Devam Et", func(): game.continue_game())
		var si := UiKit.label("Kayıt: %d. gün · %s" % [info.day, GameData.DIFF_NAMES[info.diff]], 15, Color("#6b4a2b"))
		si.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(si)
	_btn(v, "Yeni Oyun", show_new)
	_btn(v, "Nasıl Oynanır", show_help)
	_btn(v, "Ayarlar", func(): show_settings("title"))
	_btn(v, "Emeği Geçenler", show_credits)

func show_new() -> void:
	current = "new"
	var v := _panel("Yeni Oyun")
	if game.has_save():
		var w := UiKit.label("Yeni oyun mevcut kaydın üzerine yazılır.", 16, Color("#b3261e"))
		w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(w)
	var d := ["Kolay: kaynaklar daha yavaş tükenir.", "Normal: dengeli hayatta kalma.", "Zor: her şey %30 daha hızlı tükenir."]
	for i in 3:
		_btn(v, GameData.DIFF_NAMES[i], func(): game.new_game(i))
		var l := UiKit.label(d[i], 15, Color("#6b4a2b"))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	_btn(v, "Geri", show_title, 200)

func show_help() -> void:
	current = "help"
	var v := _panel("Nasıl Oynanır")
	var txt := "Hedef: 3 telsiz parçasını (anten, pil, devre kartı) harabe ve mağaralardan bulup enkazdaki telsizi onar; ya da haritanın uzak kenarındaki kervansaraya yürü.\n\n• Su: Matara (Q), vaha, kuyu (ip + kova), kaktüs (bıçak), çiy toplayıcı.\n• Sıcak: Öğlen güneşi seni çarpar; palmiye, kaya, harabe ve mağara gölgesinde bekle.\n• Gece: Hava dondurur. Ateş yak (3 odun + 2 taş), yanında kal.\n• Kum fırtınası: Uyarı gelince 60 sn içinde sığınağa gir.\n• Av: Tavşan, keklik, fennek. Çakal, yılan ve akrepten uzak dur."
	if game.touch:
		txt += "\n\nKontroller: Sol joystick ile yürü (sonuna kadar it = koş), Etkileşim, Saldır, İç ve Koş tuşları. Üstte çanta, harita, duraklat."
	else:
		txt += "\n\nKontroller: WASD/oklar yürü · Shift koş · E/Boşluk etkileşim · Sol tık/F saldır · Q matara · Tab/I çanta · M harita · Tekerlek yakınlaştır · Esc duraklat."
	var l := UiKit.label(txt, 17)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(minf(620.0, get_viewport_rect().size.x - 80), 0)
	v.add_child(l)
	_btn(v, "Geri", func(): show_title() if not game.playing else show_pause(), 200)

func show_credits() -> void:
	current = "credits"
	var v := _panel("Emeği Geçenler")
	var txt := "Kodlama ve tasarım: ClaudeBOT (FatihLabs için)\nMotor: Godot Engine 4.7 (MIT)\n\n3D modeller, arayüz, parçacıklar, efekt sesleri: Kenney (kenney.nl), CC0\nMüzik: \"Desert Travel\" DJ CrisP · \"Desert theme\" yd · \"Desert Loop\" iamoneabe (OpenGameArt, CC0)\nSesler: wind1 Luke.RUSTLTD · Fire Crackling AntumDeluge · Fantozzi's Footsteps ve Bottle/Drink qubodup · wind whoosh loop SketchMan3 (OpenGameArt, CC0)\nYazı tipleri: Baloo 2 (Ek Type) ve Nunito, SIL OFL 1.1\n\nAyrıntılar: CREDITS.md"
	var l := UiKit.label(txt, 16)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(minf(620.0, get_viewport_rect().size.x - 80), 0)
	v.add_child(l)
	_btn(v, "Geri", show_title, 200)

func show_settings(back: String) -> void:
	current = "settings"
	var v := _panel("Ayarlar")
	var ql := UiKit.label("Grafik kalitesi", 20, UiKit.INK, true)
	v.add_child(ql)
	var qh := HBoxContainer.new()
	qh.add_theme_constant_override("separation", 6)
	v.add_child(qh)
	for i in 3:
		var b := UiKit.button(Settings.QUALITY_NAMES[i], func(): Settings.set_quality(i); show_settings(back), 22, 110)
		b.custom_minimum_size.y = 52
		if Settings.quality == i:
			b.modulate = Color(1.25, 1.15, 0.7)
		qh.add_child(b)
	var qd := UiKit.label(["Gölge yok, az parçacık, %75 çözünürlük, kısa görüş.", "Gölgeler, orta parçacık, %90 çözünürlük.", "Keskin gölgeler, tam parçacık ve çözünürlük, uzak görüş."][Settings.quality], 15, Color("#6b4a2b"))
	qd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qd.custom_minimum_size.x = 340
	v.add_child(qd)
	_btn(v, "Ses: " + ("Açık" if Settings.sound else "Kapalı"), func(): Settings.set_sound(not Settings.sound); show_settings(back))
	_btn(v, "Müzik: " + ("Açık" if Settings.music else "Kapalı"), func(): Settings.set_music(not Settings.music); show_settings(back))
	_btn(v, "Geri", func(): show_title() if back == "title" else show_pause(), 200)

func show_pause() -> void:
	current = "pause"
	var v := _panel("Duraklatıldı")
	var l := UiKit.label("%d. gün · %s · Keşif %%%d" % [game.day, GameData.DIFF_NAMES[game.s.diff], game.explored_pct()], 17, Color("#6b4a2b"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	_btn(v, "Devam", func(): game.resume())
	_btn(v, "Ayarlar", func(): show_settings("pause"))
	_btn(v, "Nasıl Oynanır", show_help)
	_btn(v, "Kaydet ve Ana Menü", func(): game.quit_to_title())

func show_dead(cause: String, day: int, pct: int) -> void:
	current = "dead"
	var v := _panel("Hayatını Kaybettin", 0.55)
	var l := UiKit.label("Sebep: %s\n%d gün dayandın · Keşif %%%d" % [cause, day, pct], 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	if game.has_save():
		_btn(v, "Son şafaktan devam", func(): game.continue_game())
	_btn(v, "Yeni Oyun", show_new)
	_btn(v, "Ana Menü", func(): game.quit_to_title(false))

func show_win(how: String, day: int, pct: int) -> void:
	current = "win"
	var v := _panel("Kurtuldun!", 0.4)
	var l := UiKit.label("%s\n%d. günde kurtuldun · Keşif %%%d" % [how, day, pct], 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 360
	v.add_child(l)
	_btn(v, "Yeni Oyun", show_new)
	_btn(v, "Ana Menü", func(): game.quit_to_title(false))
