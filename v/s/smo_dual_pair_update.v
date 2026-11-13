module smo_dual_pair_update

import math

const max_n = 8
const max_d = 3
const max_input = 47

fn valid_field(x f64, low i64, high i64) bool {
	return x.is_finite() && x >= f64(low) && x <= f64(high) && f64(i64(x)) == x
}

fn pair_dot(x []f64, a int, b int, d int) f64 {
	mut sum := 0.0
	for r in 0 .. d { sum += x[a * max_d + r] * x[b * max_d + r] }
	return sum
}

fn pair_objective(alpha []f64, labels []i64, x []f64, n int, d int) f64 {
	mut sum := 0.0
	for p in 0 .. n { sum += alpha[p] }
	for p in 0 .. n {
		for q in 0 .. n {
			sum -= 0.5 * alpha[p] * alpha[q] * f64(labels[p] * labels[q]) * pair_dot(x, p, q, d)
		}
	}
	return sum
}

@[export: 'smo_dual_pair_update']
pub fn smo_dual_pair_update(input &f64, input_length usize,
	mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 6 || input_length > max_input { return -1 }
		if !valid_field(input[0], 2, max_n) || !valid_field(input[1], 1, max_d) ||
			!valid_field(input[2], 1, 5000) || !valid_field(input[3], -1000000, 1000000) { return -1 }
		n := int(input[0]); d := int(input[1]); c_milli := i64(input[2]); b_milli := i64(input[3])
		if input_length != usize(6 + 2 * n + n * d) { return -1 }
		mut labels := [max_n]i64{}
		mut alpha := [max_n]f64{}
		mut features := [max_n * max_d]f64{}
		mut negative := false; mut positive := false; mut equality := i64(0)
		mut at := 4
		for k in 0 .. n {
			if !valid_field(input[at], -1, 1) || input[at] == 0.0 { return -1 }
			labels[k] = i64(input[at]); if labels[k] < 0 { negative = true } else { positive = true }
			at++
		}
		for k in 0 .. n {
			if !valid_field(input[at], 0, c_milli) { return -1 }
			value := i64(input[at]); alpha[k] = f64(value) / 1000.0
			equality += labels[k] * value; at++
		}
		if !negative || !positive || equality != 0 { return -1 }
		for row in 0 .. n {
			for col in 0 .. d {
				if !valid_field(input[at], -32, 32) { return -1 }
				features[row * max_d + col] = input[at]; at++
			}
		}
		if !valid_field(input[at], 0, i64(n - 1)) || !valid_field(input[at + 1], 0, i64(n - 1)) { return -1 }
		i := int(input[at]); j := int(input[at + 1]); if i == j { return -1 }
		if output == nil || output_capacity < usize(n + 1) { return -2 }
		c_value := f64(c_milli) / 1000.0; bias := f64(b_milli) / 1000.0
		yi := labels[i]; yj := labels[j]; sign := yi * yj
		old_i := alpha[i]; old_j := alpha[j]
		kii := pair_dot(features[..], i, i, d); kjj := pair_dot(features[..], j, j, d); kij := pair_dot(features[..], i, j, d)
		mut error_i := bias - f64(yi); mut error_j := bias - f64(yj)
		for k in 0 .. n {
			error_i += alpha[k] * f64(labels[k]) * pair_dot(features[..], k, i, d)
			error_j += alpha[k] * f64(labels[k]) * pair_dot(features[..], k, j, d)
		}
		mut low := 0.0; mut high := 0.0
		if yi != yj { low = math.max(0.0, old_j - old_i); high = math.min(c_value, c_value + old_j - old_i) }
		else { low = math.max(0.0, old_i + old_j - c_value); high = math.min(c_value, old_i + old_j) }
		eta := 2.0 * kij - kii - kjj
		mut new_j := 0.0
		if eta < 0.0 { new_j = math.max(low, math.min(high, old_j - f64(yj) * (error_i - error_j) / eta)) }
		else {
			mut candidate := alpha
			candidate[i] = old_i + f64(sign) * (old_j - low); candidate[j] = low
			low_score := pair_objective(candidate[..], labels[..], features[..], n, d)
			candidate[i] = old_i + f64(sign) * (old_j - high); candidate[j] = high
			high_score := pair_objective(candidate[..], labels[..], features[..], n, d)
			new_j = if high_score > low_score { high } else { low }
		}
		new_i := old_i + f64(sign) * (old_j - new_j)
		delta_i := new_i - old_i; delta_j := new_j - old_j
		bias_i := bias - error_i - f64(yi) * delta_i * kii - f64(yj) * delta_j * kij
		bias_j := bias - error_j - f64(yi) * delta_i * kij - f64(yj) * delta_j * kjj
		new_bias := if new_i > 0.0 && new_i < c_value { bias_i } else if new_j > 0.0 && new_j < c_value { bias_j } else { 0.5 * (bias_i + bias_j) }
		alpha[i] = new_i; alpha[j] = new_j
		for k in 0 .. n { output[k] = alpha[k] }
		output[n] = new_bias
		return i64(n + 1)
	}
}
