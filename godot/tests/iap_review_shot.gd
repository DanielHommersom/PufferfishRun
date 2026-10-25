extends SceneTree
## App Store review screenshot for the Remove Ads purchase: the Settings screen in English with
## the REMOVE ADS button visible, at 1290×2796 (iPhone 6.7"/6.9", an exact App Store size).
## Renders off-screen in a SubViewport (the game's 393×852 layout scaled up), so the Mac screen
## size doesn't matter. Runs on the fresh test save (lives in tests/), so it never touches real
## progress.
##   godot --path godot -s res://tests/iap_review_shot.gd -- <out.png>

const OUT_SIZE := Vector2i(1290, 2796)
const LAYOUT_SIZE := Vector2i(393, 852) # the game's design size, same aspect ratio


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "user://iap_review.png"
	await process_frame # let the autoloads finish _ready()
	var sm = root.get_node("SaveManager")
	sm.language = "en"
	sm.ads_removed = false

	var vp := SubViewport.new()
	vp.size = OUT_SIZE
	vp.size_2d_override = LAYOUT_SIZE
	vp.size_2d_override_stretch = true
	vp.msaa_2d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	vp.add_child(load("res://scenes/settings.tscn").instantiate())

	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png(out)
	print("saved ", out, " ", img.get_size())
	quit()
