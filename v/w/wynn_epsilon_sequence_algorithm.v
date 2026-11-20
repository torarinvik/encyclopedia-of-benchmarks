import math

const max_n = 10
const max_input_length = 13
const max_order = 6

@[export: 'wynn_epsilon_sequence_algorithm']
pub fn wynn_epsilon_sequence_algorithm(input &f64, input_length usize,
	mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > max_input_length { return -1 }
		for i in 0 .. input_length { if !math.is_finite(input[i]) { return -1 } }
		n_value := input[0]
		k_value := input[1]
		if math.trunc(n_value) != n_value || math.trunc(k_value) != k_value ||
			n_value < 5.0 || n_value > f64(max_n) || k_value < 2.0 || k_value > 3.0 { return -1 }
		n := int(n_value)
		k := int(k_value)
		if n < 2 * k + 1 || input_length != usize(n + 2) { return -1 }
		for i in 0 .. n {
			sample := input[i + 2]
			scaled := sample * 256.0
			if sample < -2.0 || sample > 2.0 || math.trunc(scaled) != scaled { return -1 }
		}

		mut rows := [max_order + 1][max_n]f64{}
		mut valid := [max_order + 1][max_n]bool{}
		for i in 0 .. n { rows[0][i] = input[i + 2]; valid[0][i] = true }
		for order in 0 .. 2 * k {
			for i in 0 .. n - order - 1 {
				mut auxiliary_valid := true
				if order != 0 { auxiliary_valid = valid[order - 1][i + 1] }
				if !valid[order][i] || !valid[order][i + 1] || !auxiliary_valid { continue }
				denominator := rows[order][i + 1] - rows[order][i]
				if denominator == 0.0 || !math.is_finite(denominator) { continue }
				reciprocal := 1.0 / denominator
				mut auxiliary := 0.0
				if order != 0 { auxiliary = rows[order - 1][i + 1] }
				value := auxiliary + reciprocal
				if !math.is_finite(reciprocal) || !math.is_finite(value) { continue }
				rows[order + 1][i] = value
				valid[order + 1][i] = true
			}
		}

		mut needed := 0
		for order := 2; order <= 2 * k; order += 2 { needed += 2 * (n - order) }
		if output == nil || output_capacity < usize(needed) { return -2 }
		mut cursor := 0
		for order := 2; order <= 2 * k; order += 2 {
			for i in 0 .. n - order {
				if valid[order][i] { output[cursor] = 0; output[cursor + 1] = rows[order][i] }
				else { output[cursor] = 1; output[cursor + 1] = 0 }
				cursor += 2
			}
		}
		return i64(needed)
	}
}
