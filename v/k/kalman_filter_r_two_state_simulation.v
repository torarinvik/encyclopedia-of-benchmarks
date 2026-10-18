module kalman_filter_r_two_state_simulation

const max_observations = 12
const max_parseable_length = 64
const max_output_elements = 30

fn multiply_2x2(left [4]f64, right [4]f64) [4]f64 {
	mut result := [4]f64{}
	for row in 0 .. 2 {
		for column in 0 .. 2 {
			mut sum := f64(0)
			for inner in 0 .. 2 {
				sum += left[row * 2 + inner] * right[inner * 2 + column]
			}
			result[row * 2 + column] = sum
		}
	}
	return result
}

@[export: 'kalman_filter_r_two_state_simulation']
pub fn kalman_filter_r_two_state_simulation(input &f64, input_length usize, mut output &f64,
	output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > max_parseable_length ||
			input_length > max_observations { return -1 }
		for index in 0 .. input_length {
			value := input[index]
			if !value.is_finite() || value < -1000.0 || value > 1000.0 { return -1 }
		}

		transition := [4]f64{1.0, 0.0, 1.0, 1.0}
		transition_t := [4]f64{1.0, 1.0, 0.0, 1.0}
		mut state := [2]f64{input[0], 0.0}
		mut covariance := [4]f64{1.0, 0.0, 0.0, 1.0}
		mut trace := [2 * max_observations]f64{}
		mut final_state_pred := [2]f64{}
		mut final_covariance_pred := [4]f64{}

		for step in 0 .. input_length {
			for i in 0 .. 2 {
				mut sum := f64(0)
				for j in 0 .. 2 { sum += transition[i * 2 + j] * state[j] }
				final_state_pred[i] = sum
			}

			temp := multiply_2x2(transition, covariance)
			final_covariance_pred = multiply_2x2(temp, transition_t)
			final_covariance_pred[0] += 0.0001
			final_covariance_pred[3] += 0.0001

			mut h_pred := [2]f64{}
			for column in 0 .. 2 {
				mut sum := f64(0)
				sum += 1.0 * final_covariance_pred[column]
				sum += 0.0 * final_covariance_pred[2 + column]
				h_pred[column] = sum
			}
			mut innovation := f64(0)
			innovation += h_pred[0] * 1.0
			innovation += h_pred[1] * 0.0
			innovation += 0.1

			inverse_innovation := 1.0 / innovation
			mut gain := [2]f64{}
			for row in 0 .. 2 {
				mut projected := f64(0)
				projected += final_covariance_pred[row * 2] * 1.0
				projected += final_covariance_pred[row * 2 + 1] * 0.0
				gain[row] = projected * inverse_innovation
			}
			mut h_state_pred := f64(0)
			h_state_pred += 1.0 * final_state_pred[0]
			h_state_pred += 0.0 * final_state_pred[1]
			residual := input[step] - h_state_pred
			for row in 0 .. 2 { state[row] = final_state_pred[row] + gain[row] * residual }
			trace[2 * step] = state[0]
			trace[2 * step + 1] = state[1]

			gain_observation := [4]f64{gain[0] * 1.0, gain[0] * 0.0,
				gain[1] * 1.0, gain[1] * 0.0}
			mut update := [4]f64{}
			for i in 0 .. 4 { update[i] = 1.0 - gain_observation[i] }
			covariance = multiply_2x2(update, final_covariance_pred)
		}

		mut staged := [max_output_elements]f64{}
		mut out := 0
		for i in 0 .. 2 * input_length { staged[out] = trace[i]; out++ }
		staged[out] = final_state_pred[0]; out++
		staged[out] = final_state_pred[1]; out++
		staged[out] = final_covariance_pred[0]; out++
		staged[out] = final_covariance_pred[2]; out++
		staged[out] = final_covariance_pred[1]; out++
		staged[out] = final_covariance_pred[3]; out++
		result_length := out
		if result_length > max_output_elements || output == nil || output_capacity < usize(result_length) {
			return -2
		}
		for i in 0 .. result_length { output[i] = staged[i] }
		return i64(result_length)
	}
}
