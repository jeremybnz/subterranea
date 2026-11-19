shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec3 impact_dir=vec3(0.0,0.0,-1.0);
uniform float age=0.0;
uniform vec4 tint: source_color=vec4(0.3,0.9,1.0,1.0);
varying vec3 surface_point;
void vertex(){surface_point=normalize(VERTEX);}
void fragment(){
 float alignment=dot(normalize(surface_point),normalize(impact_dir));
 float ring=exp(-abs(alignment-(1.0-age*1.8))*30.0);
 float center=pow(max(0.0,alignment),16.0)*(1.0-age);
 ALBEDO=tint.rgb*1.5;
 ALPHA=(ring*0.6+center*0.35)*pow(1.0-age,1.5);
}
