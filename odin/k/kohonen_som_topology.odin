package kohonen_som_topology

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 56
MAX_MAP_SIZE :: 4
MAX_FEATURE_COUNT :: 3

exact_integer :: proc(value: f64, minimum, maximum: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(minimum) || value > f64(maximum) do return false
	return f64(i64(value)) == value
}

magnitude :: proc(value: int) -> int {
	if value < 0 do return -value
	return value
}

@(export)
kohonen_som_topology :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 4 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 1, MAX_MAP_SIZE) || !exact_integer(input[1], 1, MAX_FEATURE_COUNT) ||
		!exact_integer(input[2], 0, 8) || !exact_integer(input[3], 1, 16) do return -1
	map_size := int(input[0])
	feature_count := int(input[1])
	radius := int(input[2])
	alpha_code := int(input[3])
	cell_count := map_size * map_size
	weight_count := cell_count * feature_count
	if int(input_length) != 4 + feature_count + weight_count do return -1

	sample: [3]f64
	for feature := 0; feature < feature_count; feature += 1 {
		if !exact_integer(input[4+feature], -8, 8) do return -1
		sample[feature] = input[4+feature]
	}
	weights: [48]f64
	for index := 0; index < weight_count; index += 1 {
		value := input[4+feature_count+index]
		if !exact_integer(value, -8, 8) do return -1
		weights[index] = value
	}

	best_matching_unit := 0
	best_distance_squared := f64(0)
	for feature := 0; feature < feature_count; feature += 1 {
		difference := weights[feature] - sample[feature]
		best_distance_squared += difference * difference
	}
	best_distance := math.sqrt_f64(best_distance_squared)
	for cell := 1; cell < cell_count; cell += 1 {
		distance_squared := f64(0)
		for feature := 0; feature < feature_count; feature += 1 {
			difference := weights[cell*feature_count+feature] - sample[feature]
			distance_squared += difference * difference
		}
		distance := math.sqrt_f64(distance_squared)
		if distance < best_distance {
			best_distance = distance
			best_matching_unit = cell
		}
	}

	best_x := best_matching_unit / map_size
	best_y := best_matching_unit % map_size
	first_x := 0
	if best_x > radius { first_x = best_x - radius }
	after_x := best_x + radius + 1
	if after_x > map_size { after_x = map_size }
	first_y := 0
	if best_y > radius { first_y = best_y - radius }
	after_y := best_y + radius + 1
	if after_y > map_size { after_y = map_size }
	alpha := f64(alpha_code) / 16.0
	for x := first_x; x < after_x; x += 1 {
		for y := first_y; y < after_y; y += 1 {
			dx := magnitude(best_x - x)
			dy := magnitude(best_y - y)
			grid_distance_squared := f64(dx*dx + dy*dy)
			scale := math.exp_f64(-grid_distance_squared / (2.0 * alpha * alpha))
			for feature := 0; feature < feature_count; feature += 1 {
				index := (x*map_size+y)*feature_count+feature
				difference := sample[feature] - weights[index]
				weights[index] += alpha * scale * difference
				if math.is_nan(weights[index]) || math.is_inf(weights[index]) do return -1
			}
		}
	}

	output_length := 1 + weight_count
	if output == nil || capacity < c.size_t(output_length) do return -2
	output[0] = best_distance
	for index := 0; index < weight_count; index += 1 { output[index+1] = weights[index] }
	return i64(output_length)
}
