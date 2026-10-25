extends SceneTree
## Renders the App Store promotional image for the Remove Ads in-app purchase (1024×1024 PNG,
## no alpha): the game's own ocean and pufferfish with a "no ads" sign.
## Needs a window (not --headless):
##   godot --path godot -s res://tools/iap_image.gd

const SIZE := Vector2i(1024, 1024)
const OUT := "res://../build/store/remove_ads_1024.png"


class NoAdsSign extends Node2D:
	var radius := 150.0

	func _draw() -> void:
		draw_circle(Vector2(6, 10), radius + 6, Color(0, 0, 0, 0.25)) # soft drop shadow
		draw_circle(Vector2.ZERO, radius, Color.WHITE)
		var font: Font = load(Constants.FONT_PATH)
		var fs := int(radius * 0.95)
		var w := font.get_string_size("AD", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(-w * 0.5, fs * 0.36), "AD", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Constants.UI_BLUE)
		var ring := Color(0.86, 0.16, 0.16)
		draw_arc(Vector2.ZERO, radius - 16, 0, TAU, 96, ring, 32, true)
		var d := Vector2(1, -1).normalized() * (radius - 22)
		draw_line(-d, d, ring, 32, true)


func _initialize() -> void:
	await process_frame
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.transparent_bg = false
	vp.msaa_2d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var ocean := OceanBackground.new()
	ocean.bubble_count = 14
	vp.add_child(ocean)

	var fish := StaticFish.create(SkinLibrary.get_by_id("default"), 215.0, 10)
	fish.position = Vector2(470, 470)
	vp.add_child(fish)

	var sign := NoAdsSign.new()
	sign.position = Vector2(790, 250)
	sign.rotation = deg_to_rad(8)
	vp.add_child(sign)

	var title := Label.new()
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED # store art stays English
	title.text = "NO ADS"
	var ls := LabelSettings.new()
	ls.font = load(Constants.FONT_PATH)
	ls.font_size = 150
	ls.font_color = Constants.UI_ORANGE
	ls.outline_size = 34
	ls.outline_color = Color(0.20, 0.10, 0.0)
	ls.shadow_size = 0
	ls.shadow_color = Color(0, 0, 0, 0.35)
	ls.shadow_offset = Vector2(0, 10)
	title.label_settings = ls
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(SIZE.x, 180)
	title.position = Vector2(0, 790)
	vp.add_child(title)

	# Let the shader, bubbles and fish animation settle, then grab a frame.
	for i in 40:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8) # App Store: flattened, no transparency
	var path := ProjectSettings.globalize_path("res://").path_join("../build/store")
	DirAccess.make_dir_recursive_absolute(path)
	img.save_png(path.path_join("remove_ads_1024.png"))
	print("saved ", path.path_join("remove_ads_1024.png"))
	quit()
