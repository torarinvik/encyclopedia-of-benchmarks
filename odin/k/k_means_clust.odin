package k_means_clust

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 84

exact_integer :: proc(value: f64, minimum, maximum: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(minimum) || value > f64(maximum) do return false
	return f64(i64(value)) == value
}

@(export)
k_means_clust :: proc "c" (input: [^]f64, input_length: c.size_t, output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 1, 16) || !exact_integer(input[1], 1, 4) || !exact_integer(input[2], 1, 4) do return -1
	point_count, dimension, cluster_count := int(input[0]), int(input[1]), int(input[2])
	if cluster_count > point_count do return -1
	data_start := 3
	centroid_start := data_start + point_count*dimension
	expected_length := centroid_start + cluster_count*dimension
	if int(input_length) != expected_length do return -1
	for i := data_start; i < expected_length; i += 1 { if !exact_integer(input[i], -16, 16) do return -1 }

	assignments: [16]int
	counts: [4]int
	sums: [4][4]i64
	for point := 0; point < point_count; point += 1 {
		best_cluster := 0
		best_distance := i64(0)
		for feature := 0; feature < dimension; feature += 1 {
			value, center := i64(input[data_start+point*dimension+feature]), i64(input[centroid_start+feature])
			delta := value-center
			best_distance += delta*delta
		}
		for cluster := 1; cluster < cluster_count; cluster += 1 {
			distance := i64(0)
			for feature := 0; feature < dimension; feature += 1 {
				value, center := i64(input[data_start+point*dimension+feature]), i64(input[centroid_start+cluster*dimension+feature])
				delta := value-center
				distance += delta*delta
			}
			if distance < best_distance { best_distance = distance; best_cluster = cluster }
		}
		assignments[point] = best_cluster
		counts[best_cluster] += 1
		for feature := 0; feature < dimension; feature += 1 { sums[best_cluster][feature] += i64(input[data_start+point*dimension+feature]) }
	}
	for cluster := 0; cluster < cluster_count; cluster += 1 { if counts[cluster] == 0 do return -1 }
	output_length := point_count + cluster_count*dimension
	if output == nil || capacity < c.size_t(output_length) do return -2
	for point := 0; point < point_count; point += 1 { output[point] = f64(assignments[point]) }
	for cluster := 0; cluster < cluster_count; cluster += 1 {
		for feature := 0; feature < dimension; feature += 1 {
			output[point_count+cluster*dimension+feature] = f64(sums[cluster][feature])/f64(counts[cluster])
		}
	}
	return i64(output_length)
}
