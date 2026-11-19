shader_type spatial;
render_mode cull_disabled, depth_draw_never;
uniform float severity=0.0;
void fragment(){
 vec2 p=(UV-0.5)*2.0;
 float edge=length(p)+0.12*sin(UV.x*37.0)*cos(UV.y*29.0);
 float crack=pow(max(0.0,1.0-abs(p.x+sin(p.y*16.0)*0.12)*18.0),4.0);
 ALBEDO=vec3(0.025,0.032,0.04); ROUGHNESS=0.95;
 EMISSION=vec3(0.7,0.14,0.025)*crack*max(0.0,severity-0.65);
 ALPHA=(1.0-smoothstep(0.55,1.0,edge))*0.9*severity;
}
