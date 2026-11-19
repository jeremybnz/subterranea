shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float fade=0.35;
void vertex(){
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*length(MODEL_MATRIX[0].xyz),INV_VIEW_MATRIX[1]*length(MODEL_MATRIX[1].xyz),INV_VIEW_MATRIX[2]*length(MODEL_MATRIX[2].xyz),MODEL_MATRIX[3]);
}
void fragment(){
 vec2 p=(UV-0.5)*2.0;
 float grain=sin(UV.x*22.0+TIME*1.1)*cos(UV.y*24.0-TIME*0.7);
 float edge=length(p)+grain*0.08;
 ALBEDO=vec3(0.20,0.23,0.27)+grain*0.012;
 ALPHA=(1.0-smoothstep(0.25,1.0,edge))*fade;
}
