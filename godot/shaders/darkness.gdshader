shader_type canvas_item;
// Abyss darkness: everything outside a soft light circle around the fish is dimmed.

uniform vec2 light_pos = vec2(98.0, 426.0); // px, in the rect's local space
uniform vec2 rect_size = vec2(393.0, 852.0);
uniform float light_radius = 150.0;
uniform float strength = 0.0;

void fragment() {
	vec2 p = UV * rect_size;
	float d = distance(p, light_pos);
	float dark = smoothstep(light_radius * 0.55, light_radius * 1.6, d);
	float flicker = 1.0 + sin(TIME * 2.3) * 0.02;
	COLOR = vec4(0.0, 0.01, 0.04, dark * strength * flicker);
}
