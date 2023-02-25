RSRC                    Shader                                                                       resource_local_to_scene    resource_name    code    custom_defines    script           res://shaders/grayscale.res �          Shader          �   shader_type canvas_item;

render_mode unshaded;

void fragment() {
	vec3 scr_tex = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	float color = (scr_tex.r + scr_tex.g + scr_tex.b) / 3.0;
	COLOR = vec4(color, color, color, texture(TEXTURE, UV).a);
} RSRC