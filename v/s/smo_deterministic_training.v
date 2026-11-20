module smo_deterministic_training

import math

const max_n = 8
const max_d = 3
const max_input = 37
const tolerance = 0.001
const epsilon = 0.001

fn valid_field(x f64, low i64, high i64) bool {
	return x.is_finite() && x >= f64(low) && x <= f64(high) && f64(i64(x)) == x
}

fn kernel(points []f64, i int, j int, d int) f64 {
	mut value := 0.0
	for k in 0 .. d { value += points[i * max_d + k] * points[j * max_d + k] }
	return value
}

fn decision(index int, alpha []f64, bias f64, labels []i64, points []f64, n int, d int) f64 {
	mut value := bias
	for k in 0 .. n { value += alpha[k] * f64(labels[k]) * kernel(points, k, index, d) }
	return value
}

fn dual(alpha []f64, labels []i64, points []f64, n int, d int) f64 {
	mut value := 0.0
	for i in 0 .. n { value += alpha[i] }
	for i in 0 .. n {
		for j in 0 .. n { value -= 0.5 * alpha[i] * alpha[j] * f64(labels[i] * labels[j]) * kernel(points, i, j, d) }
	}
	return value
}

fn take_step(i int, j int, mut alpha []f64, mut bias f64, c f64,
	labels []i64, points []f64, n int, d int) bool {
	if i == j { return false }
	yi := labels[i]; yj := labels[j]; sign := yi * yj
	old_i := alpha[i]; old_j := alpha[j]
	error_i := decision(i, alpha, bias, labels, points, n, d) - f64(yi)
	error_j := decision(j, alpha, bias, labels, points, n, d) - f64(yj)
	mut low := 0.0; mut high := 0.0
	if yi != yj { low = math.max(0.0, old_j - old_i); high = math.min(c, c + old_j - old_i) }
	else { low = math.max(0.0, old_i + old_j - c); high = math.min(c, old_i + old_j) }
	if low == high { return false }
	kii := kernel(points, i, i, d); kjj := kernel(points, j, j, d); kij := kernel(points, i, j, d)
	curvature := kii + kjj - 2.0 * kij
	mut next_j := 0.0
	if curvature > 0.0 { next_j = math.max(low, math.min(high, old_j + f64(yj) * (error_i - error_j) / curvature)) }
	else {
		mut trial := [max_n]f64{}
		for k in 0 .. n { trial[k] = alpha[k] }
		trial[i] = old_i + f64(sign) * (old_j - low); trial[j] = low
		low_score := dual(trial[..], labels, points, n, d)
		trial[i] = old_i + f64(sign) * (old_j - high); trial[j] = high
		high_score := dual(trial[..], labels, points, n, d)
		if low_score > high_score + epsilon { next_j = low }
		else if high_score > low_score + epsilon { next_j = high }
		else { next_j = old_j }
	}
	if math.abs(next_j - old_j) < epsilon * (next_j + old_j + epsilon) { return false }
	next_i := old_i + f64(sign) * (old_j - next_j)
	di := next_i - old_i; dj := next_j - old_j
	bias_i := bias - error_i - f64(yi) * di * kii - f64(yj) * dj * kij
	bias_j := bias - error_j - f64(yi) * di * kij - f64(yj) * dj * kjj
	if next_i > 0.0 && next_i < c { bias = bias_i }
	else if next_j > 0.0 && next_j < c { bias = bias_j }
	else { bias = 0.5 * (bias_i + bias_j) }
	alpha[i] = next_i; alpha[j] = next_j
	return true
}

fn examine(j int, mut alpha []f64, mut bias f64, c f64, labels []i64,
	points []f64, n int, d int) bool {
	error_j := decision(j, alpha, bias, labels, points, n, d) - f64(labels[j])
	r := error_j * f64(labels[j])
	if !((r < -tolerance && alpha[j] < c) || (r > tolerance && alpha[j] > 0.0)) { return false }
	mut free_count := 0; mut preferred := -1; mut greatest_gap := -1.0
	for i in 0 .. n {
		if alpha[i] > 0.0 && alpha[i] < c {
			free_count++
			error_i := decision(i, alpha, bias, labels, points, n, d) - f64(labels[i])
			gap := math.abs(error_i - error_j)
			if gap > greatest_gap { greatest_gap = gap; preferred = i }
		}
	}
	if free_count > 1 && take_step(preferred, j, mut alpha, mut bias, c, labels, points, n, d) { return true }
	for i in 0 .. n {
		if alpha[i] > 0.0 && alpha[i] < c && take_step(i, j, mut alpha, mut bias, c, labels, points, n, d) { return true }
	}
	for i in 0 .. n { if take_step(i, j, mut alpha, mut bias, c, labels, points, n, d) { return true } }
	return false
}

@[export: 'smo_deterministic_training']
pub fn smo_deterministic_training(input &f64, input_length usize,
	mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 4 || input_length > max_input { return -1 }
		if !valid_field(input[0], 2, max_n) || !valid_field(input[1], 1, max_d) ||
			!valid_field(input[2], 1, 5000) || !valid_field(input[3], 1, 16) { return -1 }
		n := int(input[0]); d := int(input[1]); c_milli := i64(input[2]); pass_cap := int(input[3])
		if input_length != usize(4 + n + n * d) { return -1 }
		mut labels := [max_n]i64{}
		mut alpha := [max_n]f64{}
		mut points := [max_n * max_d]f64{}
		mut positive := false; mut negative := false; mut at := 4
		for i in 0 .. n {
			if !valid_field(input[at], -1, 1) || input[at] == 0.0 { return -1 }
			labels[i] = i64(input[at]); positive = positive || labels[i] > 0; negative = negative || labels[i] < 0
			at++
		}
		if !positive || !negative { return -1 }
		for i in 0 .. n {
			for k in 0 .. d {
				if !valid_field(input[at], -32, 32) { return -1 }
				points[i * max_d + k] = input[at]; at++
			}
		}
		if output == nil || output_capacity < usize(n + 4) { return -2 }
		c := f64(c_milli) / 1000.0
		mut bias := 0.0; mut changed := 0; mut examine_all := true; mut passes := 0
		for passes < pass_cap && (changed > 0 || examine_all) {
			changed = 0
			for j in 0 .. n {
				if (examine_all || (alpha[j] > 0.0 && alpha[j] < c)) && examine(j, mut alpha[..], mut bias, c, labels[..], points[..], n, d) { changed++ }
			}
			passes++
			if examine_all { examine_all = false } else if changed == 0 { examine_all = true }
		}
		mut staged := [max_n + 4]f64{}
		staged[0] = f64(passes); staged[1] = f64(changed); staged[2] = if passes < pass_cap && changed == 0 && !examine_all { 1.0 } else { 0.0 }
		for i in 0 .. n { staged[3 + i] = alpha[i] }
		staged[3 + n] = bias
		for i in 0 .. n + 4 { output[i] = staged[i] }
		return i64(n + 4)
	}
}
