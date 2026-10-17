module single_point_crossover

import math

const max_parent_length = 31
const max_input_length = 2 + 2 * max_parent_length

fn finite(value f64) bool {
	return !math.is_nan(value) && !math.is_inf(value)
}

@[export: 'single_point_crossover']
pub fn single_point_crossover(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 6 || input_length > max_input_length { return -1 }
	unsafe {
		n_value, cut_value := input[0], input[1]
		if !finite(n_value) || !finite(cut_value) { return -1 }
		if n_value < 2.0 || n_value > f64(max_parent_length) || n_value != f64(int(n_value)) ||
			cut_value < 1.0 || cut_value > n_value - 1.0 || cut_value != f64(int(cut_value)) { return -1 }
		n, cut := int(n_value), int(cut_value)
		if input_length != usize(2 + 2 * n) { return -1 }
		mut first := [max_parent_length]f64{}
		mut second := [max_parent_length]f64{}
		for index in 0 .. n {
			first[index], second[index] = input[2 + index], input[2 + n + index]
			if !finite(first[index]) || !finite(second[index]) { return -1 }
		}
		required := 2 * n
		if unsafe { output == nil } || output_capacity < usize(required) { return -2 }
		for index in 0 .. n {
			if index < cut { output[index], output[n + index] = first[index], second[index] }
			else { output[index], output[n + index] = second[index], first[index] }
		}
		return i64(required)
	}
}
