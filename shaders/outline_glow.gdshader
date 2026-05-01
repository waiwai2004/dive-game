shader_type canvas_item;
render_mode blend_add;

uniform vec4 outline_color : source_color = vec4(0.3, 0.8, 1.0, 1.0);
uniform float outline_width : hint_range(1.0, 10.0) = 4.0;

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
	vec4 sprite_color = texture(TEXTURE, UV);
	float alpha = sprite_color.a;
	
	float outline = 0.0;
	outline += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
	outline += texture(TEXTURE, UV - vec2(size.x, 0.0)).a;
	outline += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
	outline += texture(TEXTURE, UV - vec2(0.0, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
	outline += texture(TEXTURE, UV - vec2(size.x, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
	outline += texture(TEXTURE, UV - vec2(size.x, -size.y)).a;
	
	outline = min(outline, 1.0);
	
	vec3 final_color = mix(outline_color.rgb, sprite_color.rgb, sprite_color.a);
	float final_alpha = max(alpha, outline * outline_color.a);
	
	COLOR = vec4(final_color, final_alpha);
}
