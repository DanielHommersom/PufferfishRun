shader_type canvas_item;
// Animated ocean backdrop: smooth 3-colour depth gradient, swaying god rays, surface caustics
// and a soft vignette. Colours/ray strength are tweened from OceanBackground per depth zone.

uniform vec4 top_color : source_color = vec4(0.306, 0.753, 0.792, 1.0);
uniform vec4 mid_color : source_color = vec4(0.165, 0.541, 0.604, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.051, 0.227, 0.361, 1.0);
uniform vec4 ray_color : source_color = vec4(0.365, 0.831, 0.867, 1.0);
uniform float ray_alpha = 0.18;
uniform float aspect = 0.4613; // width / height
uniform float scroll = 0.0; // horizontal world scroll in screen widths (parallax for caustics)
uniform float animate = 1.0;

float caustic(vec2 p, float t) {
	float c = 0.0;
	c += sin(p.x * 9.0 + t * 0.9 + sin(p.y * 7.0 + t * 0.7) * 1.4);
	c += sin(p.y * 11.0 - t * 1.1 + sin(p.x * 6.0 - t * 0.5) * 1.6);
	c += sin((p.x + p.y) * 8.0 + t * 0.6);
	c = abs(c) / 3.0;
	return pow(1.0 - c, 6.0);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * animate;

	// Depth gradient (soft transitions at 55 % and 82 % like the original bands)
	vec3 col = mix(top_color.rgb, mid_color.rgb, smoothstep(0.30, 0.62, uv.y));
	col = mix(col, bottom_color.rgb, smoothstep(0.66, 0.92, uv.y));

	// God rays: four slanted, gently swaying beams fading out with depth
	float rays = 0.0;
	float xs[4] = float[](0.15, 0.38, 0.62, 0.82);
	for (int i = 0; i < 4; i++) {
		float fi = float(i);
		float sway = sin(t * 0.35 + fi * 1.7) * 0.025;
		float cx = xs[i] + sway + uv.y * (0.05 + 0.02 * sin(fi));
		float width = mix(0.012, 0.07, uv.y / 0.65);
		float d = abs(uv.x - cx);
		float beam = smoothstep(width, 0.0, d);
		beam *= 0.75 + 0.25 * sin(t * 0.8 + fi * 2.3);
		rays += beam;
	}
	rays *= smoothstep(0.7, 0.0, uv.y);
	col = mix(col, ray_color.rgb, clamp(rays * ray_alpha * 1.6, 0.0, 0.6));

	// Caustics near the surface
	vec2 cp = vec2(uv.x * aspect + scroll * aspect, uv.y);
	float c = caustic(cp * 1.6, t);
	col += vec3(0.8, 1.0, 1.0) * c * ray_alpha * 0.9 * smoothstep(0.45, 0.0, uv.y);

	// Vignette
	vec2 v = uv - vec2(0.5, 0.45);
	v.x *= aspect * 1.6;
	col *= 1.0 - smoothstep(0.35, 1.0, length(v)) * 0.35;

	COLOR = vec4(col, 1.0);
}
