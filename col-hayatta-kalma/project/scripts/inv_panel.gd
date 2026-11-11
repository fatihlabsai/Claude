## Bag (8 slots) + crafting panel.
extends Control

const Slot := preload("res://scripts/slot.gd")
var game: Node
var slots: Array = []
var sel := -1
var info: Label
var use_btn: Button
var drop_btn: Button
var recipe_box: VBoxContainer
var scroll: ScrollContainer
var close_btn: Button
var rects := {}

func setup(g: Node) -> void:
	game = g
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

func open() -> void:
	rects.clear()
	for c in get_children():
		c.queue_free()
	slots.clear()
	sel = -1
	var vs := get_viewport_rect().size
	var portrait := vs.x < vs.y
	var dim := ColorRect.new(); dim.color = Color(0.08, 0.04, 0.02, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	var head := HBoxContainer.new()
	root.add_child(head)
	var title := UiKit.label("Çanta ve Üretim", 30, UiKit.INK, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	close_btn = UiKit.button("Kapat", func(): game.close_panels(), 22)
	head.add_child(close_btn)
	var body: BoxContainer = VBoxContainer.new() if portrait else HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)
	# --- bag ---
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)
	left.add_child(UiKit.label("Çanta (%d yuva)" % GameData.SLOTS, 20, UiKit.INK, true))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8); grid.add_theme_constant_override("v_separation", 8)
	left.add_child(grid)
	for i in GameData.SLOTS:
		var s := Slot.new()
		s.custom_minimum_size = Vector2(76, 76)
		grid.add_child(s)
		slots.append(s)
		s.clicked.connect(_select.bind(i))
	info = UiKit.label("Bir eşya seç.", 18)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(330, 52)
	left.add_child(info)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	left.add_child(btns)
	use_btn = UiKit.button("Kullan", _use, 22)
	drop_btn = UiKit.button("Bırak", _drop, 22)
	btns.add_child(use_btn); btns.add_child(drop_btn)
	var extra := UiKit.label("", 16, Color("#6b4a2b"))
	extra.text = "Matara: %d/%d yudum · Kova: %s" % [game.canteen, game.cap, "var" if game.count("kova") > 0 else "yok"]
	left.add_child(extra)
	# --- crafting ---
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	body.add_child(right)
	right.add_child(UiKit.label("Üret", 20, UiKit.INK, true))
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(390 if not portrait else 330, clampf(vs.y - 250.0, 300.0, 460.0) if not portrait else clampf(vs.y - 560.0, 220.0, 360.0))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	recipe_box = VBoxContainer.new()
	recipe_box.add_theme_constant_override("separation", 6)
	recipe_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(recipe_box)
	refresh()
	visible = true
	await get_tree().process_frame
	panel.position = (vs - panel.size) / 2
	panel.position.y = maxf(panel.position.y, 8)
	rects["panel"] = Rect2(panel.position, panel.size)
	_collect()

## Screen rects of slots and craft buttons (read by the browser test bridge).
func _collect() -> void:
	await get_tree().process_frame
	if not visible:
		return
	for i in slots.size():
		rects["slot%d" % i] = Rect2(slots[i].global_position, slots[i].size)
	var clip := Rect2(scroll.global_position, scroll.size)
	for b in find_children("craft_*", "Button", true, false):
		var br := Rect2(b.global_position, b.size)
		if clip.encloses(br):
			rects[str(b.name)] = br
		else:
			rects.erase(str(b.name))
	rects["use"] = Rect2(use_btn.global_position, use_btn.size)
	rects["close"] = Rect2(close_btn.global_position, close_btn.size)

func refresh() -> void:
	for i in slots.size():
		var e: Variant = game.inv[i]
		slots[i].item = e.id if e else ""
		slots[i].count = e.n if e else 0
		slots[i].selected = i == sel
		slots[i].queue_redraw()
	_update_info()
	for c in recipe_box.get_children():
		c.queue_free()
	for r in GameData.RECIPES:
		recipe_box.add_child(_recipe_row(r))
	if rects.has("panel"):
		_collect()

func _recipe_row(r: Dictionary) -> Control:
	var pc := PanelContainer.new()
	var ok: bool = game.can_craft(r)
	pc.add_theme_stylebox_override("panel", UiKit.flat_box(Color("#f6e3bd") if ok else Color("#e9d4ae"), 10, 2, Color("#a0784e")))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	pc.add_child(h)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	v.add_child(UiKit.label(r.name, 20, UiKit.INK, true))
	var need := HBoxContainer.new()
	need.add_theme_constant_override("separation", 4)
	v.add_child(need)
	for id in r.needs:
		var have: int = game.count(id)
		var ic := Slot.new(); ic.small = true; ic.item = id; ic.custom_minimum_size = Vector2(26, 26); ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		need.add_child(ic)
		need.add_child(UiKit.label("%d/%d %s" % [mini(have, r.needs[id]), r.needs[id], GameData.ITEMS[id].name], 15, Color("#2f7d32") if have >= r.needs[id] else Color("#b3261e")))
	var d := UiKit.label(r.desc, 14, Color("#6b4a2b"))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	var b := UiKit.button("Yap", func(): game.craft(r); refresh(), 20)
	b.disabled = not ok
	b.name = "craft_" + r.id.replace(":", "_")
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
	return pc

func _select(i: int) -> void:
	sel = i if game.inv[i] else -1
	Sfx.play("click", -10.0)
	refresh()

func _update_info() -> void:
	if sel < 0 or game.inv[sel] == null:
		info.text = "Bir eşya seç. Yiyecek ve suyu buradan kullanabilirsin."
		use_btn.disabled = true; drop_btn.disabled = true
		use_btn.text = "Kullan"
		return
	var id: String = game.inv[sel].id
	var it: Dictionary = GameData.ITEMS[id]
	var desc = it.name
	if it.has("use"):
		var u: Dictionary = it.use
		var parts := []
		if u.has("water"): parts.append("+%d su" % u.water)
		if u.has("food"): parts.append("+%d yemek" % u.food)
		if u.has("hp"): parts.append("+%d sağlık" % u.hp)
		if u.has("sick"): parts.append("%%%d hastalık riski" % int(u.sick * 100))
		desc += ": " + ", ".join(parts)
	elif it.get("tool", false):
		desc += " (alet: çantada durması yeter)"
	elif it.get("quest", false):
		desc += " (telsiz parçası: enkazdaki telsize götür)"
	info.text = desc
	use_btn.disabled = not it.has("use")
	use_btn.text = it.get("verb", "Kullan")
	drop_btn.disabled = it.get("quest", false)

func _use() -> void:
	if sel >= 0:
		game.use_slot(sel)
		if game.inv[sel] == null:
			sel = -1
		refresh()

func _drop() -> void:
	if sel >= 0:
		game.drop_slot(sel)
		sel = -1
		refresh()
