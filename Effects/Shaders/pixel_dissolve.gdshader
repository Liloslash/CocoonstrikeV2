shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D texture_albedo;

uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform float pixel_size : hint_range(1.0, 64.0) = 8.0;
uniform float edge_glow : hint_range(0.0, 4.0) = 1.5;
uniform vec3 edge_color : source_color = vec3(1.0, 0.7, 0.2);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	ivec2 tex_resolution = textureSize(texture_albedo, 0);
	vec2 texel = 1.0 / vec2(max(tex_resolution, ivec2(1)));
	vec2 nearest_uv = (floor(uv / texel) + 0.5) * texel;
	
	vec2 pixel_uv = nearest_uv;
	if (pixel_size > 1.0) {
		pixel_uv = (floor(uv * pixel_size) + 0.5) / pixel_size;
	}
	pixel_uv = (floor(pixel_uv / texel) + 0.5) * texel;
	
	vec4 base_color = texture(texture_albedo, nearest_uv) * COLOR;
	vec4 pixel_color = texture(texture_albedo, pixel_uv) * COLOR;
	
	if (base_color.a <= 0.01) {
		discard;
	}
	
	float noise = hash(pixel_uv * 256.0);
	if (noise < dissolve_amount) {
		discard;
	}
	
	float t = max(clamp((pixel_size - 1.0) / 24.0, 0.0, 1.0), smoothstep(0.15, 0.95, dissolve_amount));
	vec3 final_rgb = mix(base_color.rgb, pixel_color.rgb, t);
	
	float border = smoothstep(dissolve_amount, dissolve_amount + 0.05, noise);
	
	ALBEDO = final_rgb;
	ALPHA = base_color.a;
	EMISSION = edge_color * border * edge_glow * base_color.a;
}

