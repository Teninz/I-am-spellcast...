shader_type canvas_item;
// Мягкий цветокор всего экрана: меньше контраста и насыщенности, приподнятые тени,
// притушенные пересветы и лёгкое «вечернее» освещение (светлее к центру, темнее к краям).
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float contrast = 0.9;
uniform float saturation = 0.85;
uniform float lift = 0.035;     // насколько поднять чёрное
uniform float gain = 0.93;      // насколько притушить белое
uniform vec3 tint = vec3(1.0, 0.97, 0.93);  // тёплый, но не оранжевый свет
uniform float vignette = 0.16;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	c = (c - 0.5) * contrast + 0.5;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	c = c * gain + lift * (1.0 - c);
	c *= tint;
	vec2 d = SCREEN_UV - 0.5;
	c *= 1.0 - vignette * smoothstep(0.25, 0.75, length(d * vec2(1.0, 0.8)));
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
