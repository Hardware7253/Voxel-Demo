shader_type spatial;

uniform vec2 grid_size = vec2(2.0, 2.0);
uniform vec3 line_color: source_color = vec3(0.2, 0.3, 0.5);
uniform vec2 line_thickness = vec2(0.01, 0.01);

// Returns 1.0 if the pixel is on the grid, 0.0 otherwise
float get_gridness(vec2 uv) {
	vec2 thickness = line_thickness * grid_size;
	vec2 grid_uv = vec2(fract(uv * grid_size - (thickness / 2.0)));

	float x_line = step(1.0 - thickness.x, grid_uv.x);
	float y_line = step(1.0 - thickness.y, grid_uv.y);
	return max(x_line, y_line);
}

void fragment() {
	float gridness = get_gridness(UV);
	vec3 color = gridness * line_color;
	ALBEDO = color;
	ALPHA = gridness;
}