module kl_divergence_loss

import math

const max_count = 64
const scale = 1_000_000.0
const epsilon = 1e-5
const invalid_result = -1.0e300

@[export: 'kl_divergence_loss']
pub fn kl_divergence_loss(input &i64, length usize) f64 {
	if unsafe { input == nil } || length < 2 || length > 130 { return invalid_result }
	unsafe {
		actual_count_value := input[0]
		predicted_count_value := input[1]
		if actual_count_value < 0 || actual_count_value > max_count || predicted_count_value < 0 || predicted_count_value > max_count { return invalid_result }
		actual_count := int(actual_count_value)
		predicted_count := int(predicted_count_value)
		if length != usize(2 + actual_count + predicted_count) { return invalid_result }
		for index in 0 .. actual_count {
			if input[2 + index] < 0 || input[2 + index] > 1_000_000 { return invalid_result }
		}
		for index in 0 .. predicted_count {
			if input[2 + actual_count + index] < 0 || input[2 + actual_count + index] > 1_000_000 { return invalid_result }
		}
		paired_count := if actual_count < predicted_count { actual_count } else { predicted_count }
		mut total := 0.0
		for index in 0 .. paired_count {
			actual := f64(input[2 + index]) / scale + epsilon
			predicted := f64(input[2 + actual_count + index]) / scale + epsilon
			total += actual * math.log(actual / predicted)
		}
		return total
	}
}
