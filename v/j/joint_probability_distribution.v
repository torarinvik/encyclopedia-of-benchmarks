module joint_probability_distribution

const max_support_length = 4
const max_parseable_input_length = 20
const max_output_elements = 48

pub fn joint_probability_distribution(input &f64, input_len usize, mut output &f64, output_capacity usize) i64 {
	if unsafe { input == nil } || input_len < 2 || input_len > max_parseable_input_length { return -1 }
	 nx_value := unsafe { input[0] }
	 ny_value := unsafe { input[1] }
	if !nx_value.is_finite() || !ny_value.is_finite() ||
		nx_value < 1.0 || nx_value > f64(max_support_length) ||
		ny_value < 1.0 || ny_value > f64(max_support_length) ||
		nx_value != f64(int(nx_value)) || ny_value != f64(int(ny_value)) { return -1 }
	nx := usize(nx_value)
	ny := usize(ny_value)
	if input_len != 2 + 2 * nx + 2 * ny { return -1 }

	x_start := usize(2)
	y_start := x_start + nx
	x_probability_start := y_start + ny
	y_probability_start := x_probability_start + nx
	mut x_values := [4]i64{}
	mut y_values := [4]i64{}
	mut x_probabilities := [4]f64{}
	mut y_probabilities := [4]f64{}

	for index in 0 .. nx {
		raw := unsafe { input[x_start + index] }
		if !raw.is_finite() || raw < -1000.0 || raw > 1000.0 || raw != f64(int(raw)) { return -1 }
		x_values[index] = i64(raw)
		probability := unsafe { input[x_probability_start + index] }
		if !probability.is_finite() || probability < -1_000_000.0 || probability > 1_000_000.0 { return -1 }
		x_probabilities[index] = probability
		for previous in 0 .. index { if x_values[previous] == x_values[index] { return -1 } }
	}
	for index in 0 .. ny {
		raw := unsafe { input[y_start + index] }
		if !raw.is_finite() || raw < -1000.0 || raw > 1000.0 || raw != f64(int(raw)) { return -1 }
		y_values[index] = i64(raw)
		probability := unsafe { input[y_probability_start + index] }
		if !probability.is_finite() || probability < -1_000_000.0 || probability > 1_000_000.0 { return -1 }
		y_probabilities[index] = probability
		for previous in 0 .. index { if y_values[previous] == y_values[index] { return -1 } }
	}

	required := 3 * nx * ny
	if required > max_output_elements { return -1 }
	if unsafe { output == nil } || output_capacity < required { return -2 }
	mut position := usize(0)
	for x_index in 0 .. nx {
		for y_index in 0 .. ny {
			unsafe {
				output[position] = f64(x_values[x_index])
				output[position + 1] = f64(y_values[y_index])
				output[position + 2] = x_probabilities[x_index] * y_probabilities[y_index]
			}
			position += 3
		}
	}
	return i64(required)
}
