module sir

const invalid_result = -1
const output_error = -2

fn in_range(value f64, minimum f64, maximum f64) bool {
	return value >= minimum && value <= maximum
}

@[export: 'sir']
pub fn sir(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 6 || input_length > 7 { return invalid_result }
		if input_length != 6 { return invalid_result }

		s, i, r, beta, k, time := input[0], input[1], input[2], input[3], input[4], input[5]
		if !in_range(s, 0.0, 1000000.0) || !in_range(i, 0.0, 1000000.0) ||
			!in_range(r, 0.0, 1000000.0) || !in_range(beta, 0.0, 0.001) ||
			!in_range(k, 0.0, 1.0) || !in_range(time, 0.0, 140.0) { return invalid_result }

		d_s := ((-beta) * s) * i
		d_i_infection := (beta * s) * i
		d_i_recovery := k * i
		d_i := d_i_infection - d_i_recovery
		d_r := k * i

		if output == nil || output_capacity < 3 { return output_error }
		output[0] = d_s
		output[1] = d_i
		output[2] = d_r
		return 3
	}
}
