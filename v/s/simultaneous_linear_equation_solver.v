module simultaneous_linear_equation_solver

import math

#include <math.h>
fn C.fma(first f64, second f64, third f64) f64

const max_equations = 5
const max_input_length = usize(31)
const max_output_bytes = 48
const i64_limit = 9.223372036854775808e18

fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'simultaneous_linear_equation_solver']
pub fn simultaneous_linear_equation_solver(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		n_value := input[0]
		if n_value < 1 || n_value > max_equations { return -1 }
		n := int(n_value)
		if int(length) != 1 + n * (n + 1) { return -1 }

		mut matrix := [30]f64{}
		mut has_zero := false
		for row in 0 .. n {
			for col in 0 .. n + 1 {
				raw := input[1 + row * (n + 1) + col]
				if raw < -100000 || raw > 100000 { return -1 }
				matrix[row * 6 + col] = f64(raw) / 1000.0
				has_zero = has_zero || raw == 0
			}
		}

		if n == 1 {
			if matrix[0] == 0 { return -1 }
		} else {
			if has_zero {
				mut full_row := n
				for row in 0 .. n {
					mut all_nonzero := true
					for col in 0 .. n + 1 {
						if matrix[row * 6 + col] == 0 { all_nonzero = false }
					}
					if all_nonzero { full_row = row; break }
				}
				if full_row == n { return -1 }
				if full_row != 0 {
					for col in 0 .. n + 1 {
						saved := matrix[full_row * 6 + col]
						for row in 0 .. full_row {
							matrix[(full_row - row) * 6 + col] = matrix[(full_row - row - 1) * 6 + col]
						}
						matrix[col] = saved
					}
				}
			}

			for level in 0 .. n - 1 {
				if matrix[level * 6 + level] == 0 { return -1 }
				for row in level .. n {
					magnitude := matrix[row * 6 + level]
					if magnitude != 0 {
						for col in level .. n + 1 { matrix[row * 6 + col] /= magnitude }
					}
				}
				mut first_row := [6]f64{}
				for col in level .. n + 1 { first_row[col] = matrix[level * 6 + col] }
				for row in level + 1 .. n {
					if matrix[row * 6 + level] != 0 {
						for col in level .. n + 1 {
							matrix[row * 6 + col] = first_row[col] - matrix[row * 6 + col]
						}
					}
				}
			}
		}

		for row in 0 .. n {
			for col in row .. n + 1 {
				value := matrix[row * 6 + col]
				if value != value || value >= 1.7976931348623157e308 || value <= -1.7976931348623157e308 { return -1 }
			}
		}
		mut solutions := [5]f64{}
		for row in 0 .. n {
			index := n - row - 1
			if matrix[index * 6 + index] == 0 { return -1 }
			mut value := matrix[index * 6 + n]
			for col in index + 1 .. n { value -= matrix[index * 6 + col] * solutions[col] }
			value /= matrix[index * 6 + index]
			if value != value || value >= 1.7976931348623157e308 || value <= -1.7976931348623157e308 { return -1 }
			solutions[index] = value
		}

		mut buffer := [max_output_bytes]u8{}
		write_i64_le(mut buffer, 0, n_value)
		for row in 0 .. n {
			scaled := solutions[row] * 100000.0
			if scaled != scaled || scaled < -i64_limit || scaled >= i64_limit { return -1 }
			lower := math.floor(scaled)
			midpoint := lower + 0.5
			exact_side := C.fma(solutions[row], 100000.0, -midpoint)
			if exact_side != exact_side || exact_side >= 1.7976931348623157e308 || exact_side <= -1.7976931348623157e308 { return -1 }
			mut rounded := i64(lower)
			if exact_side > 0 || (exact_side == 0 && rounded % 2 != 0) { rounded++ }
			write_i64_le(mut buffer, 8 + row * 8, rounded)
		}

		needed := 8 + 8 * n
		if output == nil || capacity < usize(needed) { return -2 }
		for index in 0 .. needed { output[index] = buffer[index] }
		return i64(needed)
	}
}
