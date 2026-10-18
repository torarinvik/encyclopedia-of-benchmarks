import math

fn exact_integer(value f64, minimum i64, maximum i64) bool {
	if !value.is_finite() || value < f64(minimum) || value > f64(maximum) { return false }
	return f64(i64(value)) == value
}

fn magnitude(value int) int {
	if value < 0 { return -value }
	return value
}

@[export: 'kohonen_som_topology']
pub fn kohonen_som_topology(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 4 || input_length > 56 { return -1 }
		if !exact_integer(input[0], 1, 4) || !exact_integer(input[1], 1, 3) ||
			!exact_integer(input[2], 0, 8) || !exact_integer(input[3], 1, 16) { return -1 }
		map_size := int(input[0])
		feature_count := int(input[1])
		radius := int(input[2])
		alpha_code := int(input[3])
		cell_count := map_size * map_size
		weight_count := cell_count * feature_count
		if input_length != usize(4 + feature_count + weight_count) { return -1 }

		mut sample := [3]f64{}
		for feature in 0 .. feature_count {
			value := input[4 + feature]
			if !exact_integer(value, -8, 8) { return -1 }
			sample[feature] = value
		}
		mut weights := [48]f64{}
		for index in 0 .. weight_count {
			value := input[4 + feature_count + index]
			if !exact_integer(value, -8, 8) { return -1 }
			weights[index] = value
		}

		mut best_matching_unit := 0
		mut best_distance_squared := f64(0)
		for feature in 0 .. feature_count {
			difference := weights[feature] - sample[feature]
			best_distance_squared += difference * difference
		}
		mut best_distance := math.sqrt(best_distance_squared)
		for cell in 1 .. cell_count {
			mut distance_squared := f64(0)
			for feature in 0 .. feature_count {
				difference := weights[cell * feature_count + feature] - sample[feature]
				distance_squared += difference * difference
			}
			distance := math.sqrt(distance_squared)
			if distance < best_distance {
				best_distance = distance
				best_matching_unit = cell
			}
		}

		best_x := best_matching_unit / map_size
		best_y := best_matching_unit % map_size
		first_x := if best_x > radius { best_x - radius } else { 0 }
		mut after_x := best_x + radius + 1
		if after_x > map_size { after_x = map_size }
		first_y := if best_y > radius { best_y - radius } else { 0 }
		mut after_y := best_y + radius + 1
		if after_y > map_size { after_y = map_size }
		alpha := f64(alpha_code) / 16.0
		for x in first_x .. after_x {
			for y in first_y .. after_y {
				dx := magnitude(best_x - x)
				dy := magnitude(best_y - y)
				grid_distance_squared := f64(dx * dx + dy * dy)
				scale := math.exp(-grid_distance_squared / (2.0 * alpha * alpha))
				for feature in 0 .. feature_count {
					index := (x * map_size + y) * feature_count + feature
					difference := sample[feature] - weights[index]
					weights[index] += alpha * scale * difference
					if !weights[index].is_finite() { return -1 }
				}
			}
		}

		output_length := 1 + weight_count
		if output == nil || capacity < usize(output_length) { return -2 }
		output[0] = best_distance
		for index in 0 .. weight_count { output[index + 1] = weights[index] }
		return i64(output_length)
	}
}
