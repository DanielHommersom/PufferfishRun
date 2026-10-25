extends SceneTree
## Renders the iOS launch images / boot splash from the ocean shader — the exact first frame of
## the splash sequence, so launch screen → boot splash → splash is one seamless image (PopPulse).
##   godot --path godot -s res://tools/launch_images.gd

const SHADER := preload("res://shaders/ocean.gdshader")


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
		var mat := ShaderMaterial.new()
		mat.shader = SHADER
		var zone: Array = Constants.ZONE_COLORS[0]
		mat.set_shader_parameter("top_color", zone[0])
		mat.set_shader_parameter("mid_color", zone[1])
		mat.set_shader_parameter("bottom_color", zone[2])
		mat.set_shader_parameter("ray_alpha", zone[3])
		mat.set_shader_parameter("aspect", float(spec[1].x) / spec[1].y)
		mat.set_shader_parameter("animate", 0.0) # a still frame
		rect.material = mat
		vp.add_child(rect)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGB8) # no alpha (App Store requirement for launch/icon art)
		img.save_png("res://assets/launch/%s.png" % spec[0])
		print("saved ", spec[0], " ", spec[1])
		vp.queue_free()
	quit()
