shader_type spatial;
//render_mode unshaded;

//Base material properties
uniform vec3 albedo1 : source_color;
uniform vec3 albedo2 : source_color;
uniform float metallic : hint_range(0.0, 1.0) = 0;
uniform float roughness : hint_range(0.0, 1.0) = .02;

//Samplers
uniform sampler2D wave;
uniform sampler2D texture_normal1;
uniform sampler2D texture_normal2;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D vignette;

//Water stuff
uniform vec2 wave_direction = vec2(2.0, 0.0);
uniform vec2 wave_direction2 = vec2(0.0, 1.0);
uniform float time_scale : hint_range(0.0, .2, .005) = .025;
uniform float noise_scale : hint_range(0.0, 25.0) = 10.0;
uniform float height_scale : hint_range(0.0, 1.0) = .15;

//Depth
uniform vec4 color_deep : source_color;
uniform vec4 color_shallow : source_color;
uniform float beers_law = 2.0;
uniform float depth_offset = -.75;

//Edge
uniform float edge_scale = .1;
uniform float near : hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float far : hint_range(10.0, 200.0, 5.0) = 100.0;
uniform vec3 edge_color : source_color;

// Varying.
varying mat4 CAMERA;
varying float height;
varying vec3 world_pos;

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((dot(normalize(normal), normalize(view))), amount);
}

void vertex() {
	CAMERA = INV_VIEW_MATRIX;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = texture(wave, world_pos.xz / noise_scale + TIME * time_scale).r;
	VERTEX.y += height * height_scale;
}

void fragment() {
	// Depth variables and calc
	float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV, depth_texture);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	linear_depth = VERTEX.z + linear_depth;
	
	float depth_blend = exp((linear_depth) * -beers_law);
	float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);
	
	vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_power).rgb;
	vec3 depth_color = mix(color_deep.rgb, color_shallow.rgb, depth_blend_power);
	vec3 color = mix(screen_color * depth_color, depth_color, depth_blend_power);
	
	// Edge depth calc
	float z_dif = linear_depth - FRAGCOORD.z;	
	
	// Time calcs for wave (normal map) movement.
	vec2 time = TIME * wave_direction * time_scale;  //Movement rate of first wave.
	vec2 time2 = TIME * wave_direction2 * time_scale;  //Movement rate of second wave.
	
	// Blend normal maps into one.
	vec3 normal_blend = mix(texture(texture_normal1, world_pos.xz/noise_scale + time).rgb, texture(texture_normal2, world_pos.xz/noise_scale + time2).rgb, 0.5);
	
	// Calc Fresnel.
	float fresnel = fresnel(5.0, NORMAL, VIEW);
	vec3 albedo = mix(albedo1, albedo2, fresnel);
	vec3 surface_color = mix(albedo, color, fresnel); //Interpolate albedo values by fresnel
	
	// Edge color
	vec3 edge_color_adj = mix(edge_color, color, linear_depth);
	vec3 depth_color_adj = mix(edge_color_adj, color, step(edge_scale, linear_depth));
	
	
	// Vignette
	float vignette_grad = texture(vignette, UV).x;
	
	// edge correction
	if (linear_depth <= edge_scale || linear_depth >= 1.0) {
		linear_depth = 1.0;
	}
	if (linear_depth <= edge_scale) {
		depth_color_adj = vec3(0.0);
	}
	// Out
//	ALPHA = vignette_grad;	
	ALPHA = pow(linear_depth, 0.5);	
	ALBEDO = clamp(surface_color + depth_color_adj, vec3(0.0), vec3(1.0));
//	ALBEDO = vec3(0.0, 0.0, linear_depth);


	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal_blend;
}
