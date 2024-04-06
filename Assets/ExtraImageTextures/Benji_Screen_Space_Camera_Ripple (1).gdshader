shader_type spatial;
render_mode skip_vertex_transform, unshaded;

const int num_sines = 8;

uniform bool lighting;

uniform float _VertexAmplitudeMult : hint_range(0.0, 2.0) = 0.3; // credit to acerola
uniform float _VertexAmplitude : hint_range(0.0, 3.0) = 0.4; // credit to acerola
uniform float _VertexFrequencyMult : hint_range(0.0, 2.0) = 0.9; // credit to acerola
uniform float _VertexFrequency : hint_range(0.0, 5.0) = 0.5; // credit to acerola
uniform float _VertexWavelengthMult : hint_range(0.0, 2.0) = 0.6; // credit to acerola
uniform float _VertexWavelength : hint_range(0.0, 1.0) = 0.3; // credit to acerola
uniform float _VertexPeakWidth : hint_range(0.0, 1.0) = 0.4;

uniform sampler2D screen : hint_screen_texture;

varying mat4 invViewMat;


struct Wave {
	vec2[num_sines] v; // velocity
	vec2 pos; // position
	vec2[num_sines] f; // frequency
	vec2[num_sines] w; // wavelength
	vec2[num_sines] p; // phase
	vec2[num_sines] a; // amplitude
};

Wave wave_gen(Wave w) {
	float a = _VertexAmplitude;
	float f = _VertexFrequency;
	float wav = _VertexWavelength;
	for (int i = 0; i <= (num_sines-1); i++) {
		w.a[i] = vec2(a);
		w.f[i] = vec2(2.0 * PI * f); // angular frequency
		w.w[i] = vec2(2.0 * PI / wav); // Wave number
		w.v[i] = vec2(w.f[i] / w.w[i]);
		w.p[i] = vec2(w.v[i] * (2.0 * PI / w.w[i]));
		a *= _VertexAmplitudeMult;
		f *= _VertexFrequencyMult;
		wav *= _VertexWavelengthMult;
	}
	return w;
}

vec3 sum_of_sines(float time, Wave w) {
	vec3 wave_data = vec3(0.0);
	float height = 0.0;
	float dwdx = 0.0;
	float dwdy = 0.0;
	vec2 dwdxy = vec2(0.0);
	for (int i = 0; i <= (num_sines-1); i++) {
		float amp = w.a[i].x * w.a[i].y;
		
		// Spherical wave eqn
		float r = sqrt(pow(w.pos.x, 2.0) + pow(w.pos.y, 2.0)); // symmetric on theta
		float x = r * w.w[i].x - time * w.f[i].x;
		float y = r * w.w[i].y - time * w.f[i].y;
		float s = _VertexPeakWidth;
		height += amp * r * (sin(x) + cos(y)); // non-exponential imaginary rep of sin + icos
		
		// Normals rotate opposite to the geometry so we need to negate the rotation here
		float _drdx = 2.0 * w.pos.x / r;
		float _drdy = 2.0 * w.pos.y / r;
		float _dxdx = w.w[i].x * _drdx;
		float _dydx = w.w[i].y * _drdx;
		float _dxdy = w.w[i].x * _drdy;
		float _dydy = w.w[i].y * _drdy;
		
		dwdx += amp * (r * (cos(x) * _dxdx - sin(y) * _dydx) + (r * _drdx * (sin(x) + cos(y))));
		dwdy += amp * (r * (cos(x) * _dxdy - sin(y) * _dydy) + (r * _drdy * (sin(x) + cos(y))));

		wave_data = vec3(height, dwdx, dwdy);
	}
	return wave_data;
}

void vertex() {
	Wave water_wave;
		water_wave = wave_gen(water_wave);
		water_wave.pos = vec2(VERTEX.x, VERTEX.y);
	vec3 wave_data = sum_of_sines(TIME, water_wave);
	float wave_height = wave_data.x;
	VERTEX.z = wave_height+0.2;


	TANGENT = normalize(vec3(1.0, 0.0, wave_data.y));
	BINORMAL = normalize(vec3(0.0, 1.0, wave_data.z));
	NORMAL = cross(TANGENT, BINORMAL);
//	VERTEX = vec3((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	NORMAL = MODEL_NORMAL_MATRIX * NORMAL;
	POSITION = vec4(VERTEX, 1.0);
	UV = -UV;
	
	invViewMat = INV_VIEW_MATRIX;
}

void fragment() {
	vec2 screenUV = SCREEN_UV;
	vec2 sig = vec2(sign(screenUV.x), sign(screenUV.y));
	vec2 altscreenUV = screenUV + VERTEX.z-0.2;
	vec4 s = texture(screen, altscreenUV);
	ALBEDO = s.rgb;
}

void light() {
	if (lighting) {
		vec3 light = normalize((invViewMat * vec4(LIGHT, 0.0)).xyz);
		vec3 v = normalize((invViewMat * vec4(VIEW, 0.0)).xyz);
		vec3 norm = normalize(NORMAL);

		DIFFUSE_LIGHT += ALBEDO * clamp(dot(norm, -light), 0.0, 1.0);
	}
	else {
		DIFFUSE_LIGHT += ALBEDO;
	}
}