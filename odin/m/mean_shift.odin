package mean_shift

import "core:c"
import "core:math"

MAX_POINTS :: 16
MAX_DIMENSION :: 3
MAX_INPUT_LENGTH :: 54
MARGIN :: 0.000001

distance :: proc "contextless" (a, b: [^]f64, a_start, b_start, dimensions: int) -> f64 {
	sum := 0.0
	for d := 0; d < dimensions; d += 1 { difference := a[a_start+d]-b[b_start+d]; sum += difference*difference }
	return math.pow(sum, 0.5)
}
near_threshold :: proc "contextless" (value, threshold: f64) -> bool { return math.abs(value-threshold) < MARGIN }

@(export)
mean_shift :: proc "c" (input: [^]f64, length: c.size_t, output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_INPUT_LENGTH do return -1
	for i := 0; i < int(length); i += 1 { value := input[i]; if value != value do return -1 }
	n_value, dimension_value, bandwidth, iteration_value, tolerance := input[0], input[1], input[2], input[3], input[4]
	if math.trunc(n_value) != n_value || math.trunc(dimension_value) != dimension_value || math.trunc(iteration_value) != iteration_value do return -1
	if n_value < 1 || n_value > MAX_POINTS || dimension_value < 1 || dimension_value > MAX_DIMENSION || iteration_value < 1 || iteration_value > 64 || bandwidth < 0.5 || bandwidth > 20 || tolerance < 1e-5 || tolerance > 1e-2 do return -1
	n, dimensions, max_iterations := int(n_value), int(dimension_value), int(iteration_value)
	if int(length) != 5+n*dimensions do return -1
	var data: [MAX_POINTS*MAX_DIMENSION]f64
	for i := 0; i < n*dimensions; i += 1 { data[i] = input[5+i]; if data[i] < -10 || data[i] > 10 do return -1 }
	var candidates, next: [MAX_POINTS*MAX_DIMENSION]f64
	for i := 0; i < n*dimensions; i += 1 { candidates[i] = data[i] }
	for _ := 0; _ < max_iterations; _ += 1 {
		for c_index := 0; c_index < n; c_index += 1 {
			var sums: [MAX_DIMENSION]f64
			neighbors := 0
			for p := 0; p < n; p += 1 {
				 dist := distance(&data[0], &candidates[0], p*dimensions, c_index*dimensions, dimensions)
				if near_threshold(dist, bandwidth) do return -1
				if dist <= bandwidth { neighbors += 1; for d := 0; d < dimensions; d += 1 { sums[d] += data[p*dimensions+d] } }
			}
			for d := 0; d < dimensions; d += 1 { next[c_index*dimensions+d] = if neighbors == 0 do candidates[c_index*dimensions+d] else sums[d]/f64(neighbors) }
		}
		all_converged := true
		for c_index := 0; c_index < n; c_index += 1 {
			movement := distance(&candidates[0], &next[0], c_index*dimensions, c_index*dimensions, dimensions)
			if near_threshold(movement, tolerance) do return -1
			if movement >= tolerance { all_converged = false; break }
		}
		if all_converged do break
		for i := 0; i < n*dimensions; i += 1 { candidates[i] = next[i] }
	}
	var centroids: [MAX_POINTS*MAX_DIMENSION]f64
	centroid_count := 0
	for c_index := 0; c_index < n; c_index += 1 {
		keep := true
		for existing := 0; existing < centroid_count; existing += 1 {
			dist := distance(&candidates[0], &centroids[0], c_index*dimensions, existing*dimensions, dimensions)
			if near_threshold(dist, bandwidth) do return -1
			if dist < bandwidth { keep = false; break }
		}
		if keep { for d := 0; d < dimensions; d += 1 { centroids[centroid_count*dimensions+d] = candidates[c_index*dimensions+d] }; centroid_count += 1 }
	}
	var labels: [MAX_POINTS]f64
	for p := 0; p < n; p += 1 {
		best_index := 0
		best_distance := distance(&data[0], &centroids[0], p*dimensions, 0, dimensions)
		for c_index := 1; c_index < centroid_count; c_index += 1 {
			dist := distance(&data[0], &centroids[0], p*dimensions, c_index*dimensions, dimensions)
			if dist != best_distance && near_threshold(dist, best_distance) do return -1
			if dist < best_distance { best_index = c_index; best_distance = dist }
		}
		labels[p] = f64(best_index)
	}
	if output == nil || capacity < c.size_t(n) do return -2
	for i := 0; i < n; i += 1 { output[i] = labels[i] }
	return i64(n)
}
