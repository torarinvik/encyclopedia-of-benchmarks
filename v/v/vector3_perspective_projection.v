module main

const input_limit = 1_000_000.0
const denominator_floor = 0.000001
const output_limit = 1.0e25

@[export: 'vector3_perspective_projection']
pub fn vector3_perspective_projection(input &f64, input_len usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_len != 5 { return -1 }
		for i in 0 .. 5 {
			value := input[i]
			if value != value || value < -input_limit || value > input_limit { return -1 }
		}
		denominator := input[2] + input[4]
		if denominator > -denominator_floor && denominator < denominator_floor { return -1 }
		x := ((input[0] * input[4]) / denominator) * input[3]
		y := ((input[1] * input[4]) / denominator) * input[3]
		if x != x || y != y || x < -output_limit || x > output_limit || y < -output_limit || y > output_limit { return -1 }
		if output == nil || output_capacity < 2 { return -2 }
		output[0] = x
		output[1] = y
		return 2
	}
}
