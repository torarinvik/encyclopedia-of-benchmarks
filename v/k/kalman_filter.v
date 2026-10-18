module kalman_filter

import math

const max_steps = 12
const max_parseable_length = 64
const scale = 1000000.0

@[export: 'kalman_filter']
pub fn kalman_filter(input &f64, length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_parseable_length { return -1 }
		for index in 0 .. length {
			if input[index] != input[index] || math.floor(input[index]) != input[index] { return -1 }
		}
		raw_steps := input[4]
		if raw_steps < 1.0 || raw_steps > f64(max_steps) { return -1 }
		steps := int(raw_steps)
		if length != usize(5 + steps) { return -1 }
		if input[0] < -1000000000.0 || input[0] > 1000000000.0 ||
			input[1] < 0.0 || input[1] > 1000000000000.0 ||
			input[2] < 0.0 || input[2] > 1000000000000.0 ||
			input[3] < 1.0 || input[3] > 1000000000000.0 { return -1 }
		for index in 0 .. steps {
			measurement := input[5 + index]
			if measurement < -1000000000.0 || measurement > 1000000000.0 { return -1 }
		}

		required := 3 * steps
		if output == nil || output_capacity < usize(required) { return -2 }
		mut estimate := input[0] / scale
		mut covariance := input[1] / scale
		process_noise := input[2] / scale
		measurement_noise := input[3] / scale
		for step in 0 .. steps {
			measurement := input[5 + step] / scale
			estimate += 0.0
			covariance += process_noise
			innovation_variance := covariance + measurement_noise
			gain := covariance / innovation_variance
			estimate += gain * (measurement - estimate)
			covariance = covariance * measurement_noise / innovation_variance
			output[3 * step] = estimate
			output[3 * step + 1] = covariance
			output[3 * step + 2] = gain
		}
		return i64(required)
	}
}
