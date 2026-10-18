package kohonen_som_trace

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 41
MAX_NODE_COUNT :: 8
MAX_FEATURE_COUNT :: 4

exact_integer :: proc(value: f64, minimum, maximum: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(minimum) || value > f64(maximum) do return false
	return f64(i64(value)) == value
}

@(export)
kohonen_som_trace :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 4 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 1, MAX_NODE_COUNT) || !exact_integer(input[1], 1, MAX_FEATURE_COUNT) ||
		!exact_integer(input[2], 0, 8) || !exact_integer(input[3], 1, 16) do return -1
	node_count := int(input[0])
	feature_count := int(input[1])
	radius := int(input[2])
	alpha_code := int(input[3])
	weight_count := node_count * feature_count
	if int(input_length) != 4 + feature_count + weight_count do return -1

	sample: [4]f64
	for feature := 0; feature < feature_count; feature += 1 {
		if !exact_integer(input[4+feature], -8, 8) do return -1
		sample[feature] = input[4+feature]
	}
	weights: [32]f64
	for index := 0; index < weight_count; index += 1 {
		value := input[4+feature_count+index]
		if !exact_integer(value, -8, 8) do return -1
		weights[index] = value
	}

	best_matching_unit := 0
	best_distance := f64(0)
	for feature := 0; feature < feature_count; feature += 1 {
		difference := weights[feature] - sample[feature]
		best_distance += difference * difference
	}
	for node := 1; node < node_count; node += 1 {
		distance := f64(0)
		for feature := 0; feature < feature_count; feature += 1 {
			difference := weights[node*feature_count+feature] - sample[feature]
			distance += difference * difference
		}
		if distance < best_distance {
			best_distance = distance
			best_matching_unit = node
		}
	}

	first_node := 0
	if best_matching_unit > radius { first_node = best_matching_unit - radius }
	after_last_node := best_matching_unit + radius + 1
	if after_last_node > node_count { after_last_node = node_count }
	alpha := f64(alpha_code) / 16
	for node := first_node; node < after_last_node; node += 1 {
		for feature := 0; feature < feature_count; feature += 1 {
			index := node*feature_count+feature
			difference := sample[feature] - weights[index]
			weights[index] += alpha * difference
			if math.is_nan(weights[index]) || math.is_inf(weights[index]) do return -1
		}
	}

	if output == nil || capacity < c.size_t(weight_count) do return -2
	for index := 0; index < weight_count; index += 1 { output[index] = weights[index] }
	return i64(weight_count)
}
