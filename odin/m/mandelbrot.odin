package mandelbrot

import "core:c"

rounded_add :: #force_no_inline proc "contextless" (left, right: f64) -> f64 { return left + right }
rounded_subtract :: #force_no_inline proc "contextless" (left, right: f64) -> f64 { return left - right }
rounded_multiply :: #force_no_inline proc "contextless" (left, right: f64) -> f64 { return left * right }
rounded_divide :: #force_no_inline proc "contextless" (left, right: f64) -> f64 { return left / right }

@(export)
mandelbrot :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 6 do return -1
	width_value := input[0]
	height_value := input[1]
	center_x_q := input[2]
	center_y_q := input[3]
	figure_width_q := input[4]
	max_step_value := input[5]
	if width_value < 1 || width_value > 16 || height_value < 1 || height_value > 16 ||
		center_x_q < -64 || center_x_q > 64 || center_y_q < -64 || center_y_q > 64 ||
		figure_width_q < 1 || figure_width_q > 64 || max_step_value < 2 || max_step_value > 64 do return -1
	width := int(width_value)
	height := int(height_value)
	max_step := int(max_step_value)
	pixel_count := width * height
	if output == nil || capacity < c.size_t(pixel_count) do return -2

	center_x := f64(center_x_q) / 16.0
	center_y := f64(center_y_q) / 16.0
	figure_width := f64(figure_width_q) / 16.0
	figure_height := rounded_multiply(rounded_divide(figure_width, f64(width)), f64(height))
	offset := 0
	for image_x := 0; image_x < width; image_x += 1 {
		x_position := rounded_subtract(rounded_divide(f64(image_x), f64(width)), 0.5)
		figure_x := rounded_add(center_x, rounded_multiply(x_position, figure_width))
		for image_y := 0; image_y < height; image_y += 1 {
			y_position := rounded_subtract(rounded_divide(f64(image_y), f64(height)), 0.5)
			figure_y := rounded_add(center_y, rounded_multiply(y_position, figure_height))
			a := figure_x
			b := figure_y
			current_step := 0
			for step := 0; step < max_step; step += 1 {
				current_step = step
				a_new := rounded_add(rounded_subtract(rounded_multiply(a, a), rounded_multiply(b, b)), figure_x)
				b = rounded_add(rounded_multiply(rounded_multiply(2.0, a), b), figure_y)
				a = a_new
				if rounded_add(rounded_multiply(a, a), rounded_multiply(b, b)) > 4.0 do break
			}
			normalized_distance := rounded_divide(f64(current_step), f64(max_step-1))
			output[offset] = if normalized_distance >= 1.0 do 0 else 255
			offset += 1
		}
	}
	return i64(pixel_count)
}
