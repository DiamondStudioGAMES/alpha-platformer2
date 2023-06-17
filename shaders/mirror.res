RSRC                    Shader                                                                       resource_local_to_scene    resource_name    code    custom_defines    script           res://shaders/mirror.res �          Shader          m  shader_type canvas_item;
render_mode unshaded;


uniform float x_scale = 1.0;
uniform float direction = -1.0;


void fragment() {
	float uv_width = SCREEN_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.x;
	vec2 reflected_screen_uv = vec2(SCREEN_UV.x + uv_width * direction * x_scale * 2.0 * UV.x, SCREEN_UV.y);
	
	COLOR = textureLod(SCREEN_TEXTURE, reflected_screen_uv, 0.0);
} RSRC