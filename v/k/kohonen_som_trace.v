fn exact_integer(value f64, minimum i64, maximum i64) bool {
	if !value.is_finite() || value < f64(minimum) || value > f64(maximum) { return false }
	return f64(i64(value)) == value
}

@[export: 'kohonen_som_trace']
pub fn kohonen_som_trace(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 4 || input_length > 41 { return -1 }
		if !exact_integer(input[0], 1, 8) || !exact_integer(input[1], 1, 4) ||
			!exact_integer(input[2], 0, 8) || !exact_integer(input[3], 1, 16) { return -1 }
		node_count := int(input[0])
		feature_count := int(input[1])
		radius := int(input[2])
		alpha_code := int(input[3])
		weight_count := node_count * feature_count
		if input_length != usize(4 + feature_count + weight_count) { return -1 }

		mut sample := [4]f64{}
		for feature in 0 .. feature_count {
			value := input[4 + feature]
			if !exact_integer(value, -8, 8) { return -1 }
			sample[feature] = value
		}
		mut weights := [32]f64{}
		for index in 0 .. weight_count {
			value := input[4 + feature_count + index]
			if !exact_integer(value, -8, 8) { return -1 }
			weights[index] = value
		}

		mut best_matching_unit := 0
		mut best_distance := f64(0)
		for feature in 0 .. feature_count {
			difference := weights[feature] - sample[feature]
			best_distance += difference * difference
		}
		for node in 1 .. node_count {
			mut distance := f64(0)
			for feature in 0 .. feature_count {
				difference := weights[node * feature_count + feature] - sample[feature]
				distance += difference * difference
			}
			if distance < best_distance {
				best_distance = distance
				best_matching_unit = node
			}
		}

		first_node := if best_matching_unit > radius { best_matching_unit - radius } else { 0 }
		mut after_last_node := best_matching_unit + radius + 1
		if after_last_node > node_count { after_last_node = node_count }
		alpha := f64(alpha_code) / 16.0
		for node in first_node .. after_last_node {
			for feature in 0 .. feature_count {
				index := node * feature_count + feature
				difference := sample[feature] - weights[index]
				weights[index] += alpha * difference
				if !weights[index].is_finite() { return -1 }
			}
		}

		if output == nil || capacity < usize(weight_count) { return -2 }
		for index in 0 .. weight_count { output[index] = weights[index] }
		return i64(weight_count)
	}
}
