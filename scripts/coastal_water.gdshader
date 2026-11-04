shader_type spatial;
render_mode unshaded;
varying vec3 world;
void vertex(){world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;}
void fragment(){
    float wave = sin(world.z*0.8+sin(world.x*0.17+TIME*0.3)*2.0-TIME*0.6);
    float ripple = smoothstep(0.94,1.0,wave)*0.1;
    ALBEDO = mix(vec3(0.018,0.15,0.23),vec3(0.04,0.28,0.35),wave*0.15+0.45)+vec3(ripple*0.4,ripple,ripple);
}
