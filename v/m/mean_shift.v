module mean_shift

import math

const max_points = 16
const max_dimension = 3
const max_input_length = 54
const margin = 1.0e-6

fn distance(a &f64, b &f64, a_start int, b_start int, dimensions int) f64 {
	mut sum := 0.0
	unsafe {
		for d in 0 .. dimensions { difference := a[a_start + d] - b[b_start + d]; sum += difference * difference }
	}
	return math.pow(sum, 0.5)
}
fn near_threshold(value f64, threshold f64) bool { return math.abs(value - threshold) < margin }

@[export: 'mean_shift']
pub fn mean_shift(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length < 5 || length > max_input_length { return -1 }
	unsafe {
		for i in 0 .. int(length) { if input[i] != input[i] { return -1 } }
		n_value := input[0]; dimension_value := input[1]; bandwidth := input[2]; iteration_value := input[3]; tolerance := input[4]
		if math.trunc(n_value) != n_value || math.trunc(dimension_value) != dimension_value || math.trunc(iteration_value) != iteration_value { return -1 }
		if n_value < 1 || n_value > max_points || dimension_value < 1 || dimension_value > max_dimension || iteration_value < 1 || iteration_value > 64 || bandwidth < 0.5 || bandwidth > 20.0 || tolerance < 1.0e-5 || tolerance > 1.0e-2 { return -1 }
		n := int(n_value); dimensions := int(dimension_value); max_iterations := int(iteration_value)
		if length != usize(5 + n * dimensions) { return -1 }
		mut data := [48]f64{}
		for i in 0 .. n * dimensions { value := input[5 + i]; if value < -10.0 || value > 10.0 { return -1 }; data[i] = value }
		mut candidates := [48]f64{}
		mut next := [48]f64{}
		for i in 0 .. n * dimensions { candidates[i] = data[i] }
		for _ in 0 .. max_iterations {
			for c in 0 .. n {
				mut sums := [3]f64{}
				mut neighbors := 0
				for p in 0 .. n {
					dist := distance(&data[0], &candidates[0], p * dimensions, c * dimensions, dimensions)
					if near_threshold(dist, bandwidth) { return -1 }
					if dist <= bandwidth { neighbors++; for d in 0 .. dimensions { sums[d] += data[p * dimensions + d] } }
				}
				for d in 0 .. dimensions { next[c * dimensions + d] = if neighbors == 0 { candidates[c * dimensions + d] } else { sums[d] / f64(neighbors) } }
			}
			mut all_converged := true
			for c in 0 .. n {
				movement := distance(&candidates[0], &next[0], c * dimensions, c * dimensions, dimensions)
				if near_threshold(movement, tolerance) { return -1 }
				if movement >= tolerance { all_converged = false; break }
			}
			if all_converged { break }
			for i in 0 .. n * dimensions { candidates[i] = next[i] }
		}
		mut centroids := [48]f64{}
		mut centroid_count := 0
		for c in 0 .. n {
			mut keep := true
			for existing in 0 .. centroid_count {
				dist := distance(&candidates[0], &centroids[0], c * dimensions, existing * dimensions, dimensions)
				if near_threshold(dist, bandwidth) { return -1 }
				if dist < bandwidth { keep = false; break }
			}
			if keep { for d in 0 .. dimensions { centroids[centroid_count * dimensions + d] = candidates[c * dimensions + d] }; centroid_count++ }
		}
		mut labels := [16]f64{}
		for p in 0 .. n {
			mut best_index := 0
			mut best_distance := distance(&data[0], &centroids[0], p * dimensions, 0, dimensions)
			for c in 1 .. centroid_count {
				dist := distance(&data[0], &centroids[0], p * dimensions, c * dimensions, dimensions)
				if dist != best_distance && near_threshold(dist, best_distance) { return -1 }
				if dist < best_distance { best_index = c; best_distance = dist }
			}
			labels[p] = f64(best_index)
		}
		if output == nil || capacity < usize(n) { return -2 }
		for i in 0 .. n { output[i] = labels[i] }
		return i64(n)
	}
}
