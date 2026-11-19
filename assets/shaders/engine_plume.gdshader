shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(0.35,0.9,1.0,1.0);
uniform float power=1.0;
uniform float engine_health=1.0;
void fragment() {
    float along=1.0-UV.y;
    float pulse=0.84+0.16*sin(TIME*18.0+UV.y*21.0);
    pulse*=mix(0.45+0.55*step(-0.3,sin(TIME*25.0)),1.0,smoothstep(0.15,0.5,engine_health));
    float body=smoothstep(0.0,0.13,along)*pow(1.0-along,1.3);
    ALBEDO=mix(tint.rgb,vec3(0.8,0.95,1.0),body*0.5)*1.8;
    ALPHA=body*pulse*0.58*clamp(power,0.35,1.8);
}
