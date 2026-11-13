package smo_dual_pair_update

import "core:c"
import "core:math"

MAX_N :: 8
MAX_D :: 3
MAX_INPUT :: 47

field :: proc(x: f64, low, high: i64) -> bool {
	if math.is_nan(x) || math.is_inf(x) || x < f64(low) || x > f64(high) do return false
	return f64(i64(x)) == x
}

pair_dot :: proc(features: []f64, left, right, dimension: int) -> f64 {
	total := f64(0.0)
	for r := 0; r < dimension; r += 1 {
		total += features[left * MAX_D + r] * features[right * MAX_D + r]
	}
	return total
}

pair_objective :: proc(alpha: []f64, labels: []i64, features: []f64,
	n, dimension: int) -> f64 {
	total := f64(0.0)
	for p := 0; p < n; p += 1 { total += alpha[p] }
	for p := 0; p < n; p += 1 {
		for q := 0; q < n; q += 1 {
			total -= 0.5 * alpha[p] * alpha[q] * f64(labels[p] * labels[q]) *
				pair_dot(features, p, q, dimension)
		}
	}
	return total
}

@(export)
smo_dual_pair_update :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 6 || input_length > MAX_INPUT do return -1
	if !field(input[0], 2, MAX_N) || !field(input[1], 1, MAX_D) ||
		!field(input[2], 1, 5000) || !field(input[3], -1_000_000, 1_000_000) do return -1
	n := int(input[0]); dimension := int(input[1])
	c_milli := i64(input[2]); b_milli := i64(input[3])
	if input_length != c.size_t(6 + 2*n + n*dimension) do return -1

	var labels: [MAX_N]i64
	var alpha: [MAX_N]f64
	var features: [MAX_N * MAX_D]f64
	negative := false; positive := false; equality := i64(0)
	at := 4
	for k := 0; k < n; k += 1 {
		if !field(input[at], -1, 1) || input[at] == 0.0 do return -1
		labels[k] = i64(input[at])
		if labels[k] < 0 do negative = true else do positive = true
		at += 1
	}
	for k := 0; k < n; k += 1 {
		if !field(input[at], 0, c_milli) do return -1
		value := i64(input[at])
		alpha[k] = f64(value) / 1000.0
		equality += labels[k] * value
		at += 1
	}
	if !negative || !positive || equality != 0 do return -1
	for row := 0; row < n; row += 1 {
		for col := 0; col < dimension; col += 1 {
			if !field(input[at], -32, 32) do return -1
			features[row * MAX_D + col] = input[at]
			at += 1
		}
	}
	if !field(input[at], 0, i64(n-1)) || !field(input[at+1], 0, i64(n-1)) do return -1
	i := int(input[at]); j := int(input[at+1])
	if i == j do return -1
	if output == nil || output_capacity < c.size_t(n+1) do return -2

	c_value := f64(c_milli) / 1000.0; bias := f64(b_milli) / 1000.0
	yi := labels[i]; yj := labels[j]; sign := yi * yj
	old_i := alpha[i]; old_j := alpha[j]
	kii := pair_dot(features[:], i, i, dimension)
	kjj := pair_dot(features[:], j, j, dimension)
	kij := pair_dot(features[:], i, j, dimension)
	error_i := bias - f64(yi); error_j := bias - f64(yj)
	for k := 0; k < n; k += 1 {
		error_i += alpha[k] * f64(labels[k]) * pair_dot(features[:], k, i, dimension)
		error_j += alpha[k] * f64(labels[k]) * pair_dot(features[:], k, j, dimension)
	}
	low := f64(0.0); high := f64(0.0)
	if yi != yj {
		low = math.max(0.0, old_j-old_i)
		high = math.min(c_value, c_value+old_j-old_i)
	} else {
		low = math.max(0.0, old_i+old_j-c_value)
		high = math.min(c_value, old_i+old_j)
	}
	eta := 2.0*kij-kii-kjj
	new_j := f64(0.0)
	if eta < 0.0 {
		new_j = math.max(low, math.min(high, old_j-f64(yj)*(error_i-error_j)/eta))
	} else {
		var candidate: [MAX_N]f64
		for k := 0; k < n; k += 1 { candidate[k] = alpha[k] }
		candidate[i] = old_i+f64(sign)*(old_j-low); candidate[j] = low
		low_score := pair_objective(candidate[:], labels[:], features[:], n, dimension)
		candidate[i] = old_i+f64(sign)*(old_j-high); candidate[j] = high
		high_score := pair_objective(candidate[:], labels[:], features[:], n, dimension)
		new_j = high if high_score > low_score else low
	}
	new_i := old_i+f64(sign)*(old_j-new_j)
	delta_i := new_i-old_i; delta_j := new_j-old_j
	bias_i := bias-error_i-f64(yi)*delta_i*kii-f64(yj)*delta_j*kij
	bias_j := bias-error_j-f64(yi)*delta_i*kij-f64(yj)*delta_j*kjj
	new_bias := bias_i if new_i > 0.0 && new_i < c_value else
		bias_j if new_j > 0.0 && new_j < c_value else 0.5*(bias_i+bias_j)
	alpha[i] = new_i; alpha[j] = new_j
	for k := 0; k < n; k += 1 { output[k] = alpha[k] }
	output[n] = new_bias
	return i64(n+1)
}
