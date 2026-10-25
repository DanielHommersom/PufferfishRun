extends SceneTree
## Renders the iOS launch images: one flat Constants.LAUNCH_BG, the same colour as Godot's boot
## screen (show_image = false, so Godot never draws its own logo) and the first frame of the
## splash sequence, so launch → boot → studio logo is seamless.
##   godot --path godot -s res://tools/launch_images.gd

func _initialize() -> void:
	await process_frame
	for spec in [["launch@3x", Vector2i(1290, 2796)], ["launch@2x", Vector2i(828, 1792)]]:
		var vp := SubViewport.new()
		vp.size = spec[1]
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		vp.transparent_bg = false
		root.add_child(vp)
		var rect := ColorRect.new()
		rect.size = Vector2(spec[1])
		rect.color = Constants.LAUNCH_BG
		vp.add_child(rect)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGB8) # no alpha (App Store requirement for launch/icon art)
		img.save_png("res://assets/launch/%s.png" % spec[0])
		print("saved ", spec[0], " ", spec[1])
		vp.queue_free()
	quit()
