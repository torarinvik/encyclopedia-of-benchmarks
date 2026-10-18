import math

const max_samples = 8
const max_features = 3
const max_input = 101

@[export: 'mini_batch_gradient_descent']
pub fn mini_batch_gradient_descent(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 5 || input_length > max_input { return -1 }
		for i in 0 .. 4 {
			if !input[i].is_finite() || math.floor(input[i]) != input[i] { return -1 }
		}
		if input[0] < 1 || input[0] > max_samples || input[1] < 1 || input[1] > max_features { return -1 }
		samples := int(input[0])
		features := int(input[1])
		if input[2] < 1 || input[2] > f64(samples) || input[3] < 0 || input[3] > 8 { return -1 }
		batch_size := int(input[2])
		epochs := int(input[3])
		learning_rate := input[4]
		if !learning_rate.is_finite() || learning_rate < 0 || learning_rate > 0.25 { return -1 }
		matrix_start := 5
		targets_start := matrix_start + samples * features
		permutations_start := targets_start + samples
		if input_length != usize(permutations_start + epochs * samples) { return -1 }

		mut matrix := [max_samples * max_features]f64{}
		mut targets := [max_samples]f64{}
		for i in 0 .. samples * features {
			value := input[matrix_start + i]
			if !value.is_finite() || math.abs(value) > 10 { return -1 }
			matrix[i] = value
		}
		for i in 0 .. samples {
			value := input[targets_start + i]
			if !value.is_finite() || math.abs(value) > 100 { return -1 }
			targets[i] = value
		}
		mut permutations := [64]int{}
		for epoch in 0 .. epochs {
			mut seen := [max_samples]bool{}
			for position in 0 .. samples {
				raw := input[permutations_start + epoch * samples + position]
				if !raw.is_finite() || math.floor(raw) != raw || raw < 0 || raw >= f64(samples) { return -1 }
				sample := int(raw)
				if seen[sample] { return -1 }
				seen[sample] = true
				permutations[epoch * samples + position] = sample
			}
		}

		mut weights := [max_features]f64{}
		mut bias := 0.0
		for epoch in 0 .. epochs {
			mut start := 0
			for start < samples {
				batch_length := if samples - start < batch_size { samples - start } else { batch_size }
				mut errors := [max_samples]f64{}
				for position in 0 .. batch_length {
					sample := permutations[epoch * samples + start + position]
					mut prediction := 0.0
					for feature in 0 .. features {
						prediction += matrix[sample * features + feature] * weights[feature]
						if !prediction.is_finite() { return -1 }
					}
					prediction += bias
					error := prediction - targets[sample]
					if !prediction.is_finite() || !error.is_finite() { return -1 }
					errors[position] = error
				}
				for feature in 0 .. features {
					mut gradient := 0.0
					for position in 0 .. batch_length {
						sample := permutations[epoch * samples + start + position]
						gradient += matrix[sample * features + feature] * errors[position]
						if !gradient.is_finite() { return -1 }
					}
					update := (learning_rate * gradient) / f64(batch_length)
					weights[feature] -= update
					if !update.is_finite() || !weights[feature].is_finite() { return -1 }
				}
				mut error_sum := 0.0
				for position in 0 .. batch_length {
					error_sum += errors[position]
					if !error_sum.is_finite() { return -1 }
				}
				mean_error := error_sum / f64(batch_length)
				bias_update := learning_rate * mean_error
				bias -= bias_update
				if !mean_error.is_finite() || !bias_update.is_finite() || !bias.is_finite() { return -1 }
				start += batch_length
			}
		}
		mut staged := [max_features + 1]f64{}
		for feature in 0 .. features { staged[feature] = weights[feature] }
		staged[features] = bias
		if output == nil || capacity < usize(features + 1) { return -2 }
		for i in 0 .. features + 1 { output[i] = staged[i] }
		return i64(features + 1)
	}
}
