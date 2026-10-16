module main

import math

const max_dimension = 8
const max_iterations = 1000

fn write_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.f64_bits(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'conjugate_gradient']
pub fn conjugate_gradient(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || input[0] < 1 || input[0] > max_dimension { return -1 }
		n := int(input[0])
		if int(length) != 1 + n * n + n { return -1 }
		vector_offset := 1 + n * n
		mut matrix := [64]f64{}
		mut rhs := [8]f64{}
		mut solution := [8]f64{}
		mut residual := [8]f64{}
		mut direction := [8]f64{}
		mut product := [8]f64{}
		for index in 0 .. n * n + n {
			if input[index + 1] < -1_000_000_000 || input[index + 1] > 1_000_000_000 { return -1 }
		}
		for row in 0 .. n {
			diagonal := input[1 + row * n + row]
			if diagonal <= 0 { return -1 }
			mut off_diagonal_sum := i64(0)
			for column in 0 .. n {
				entry := input[1 + row * n + column]
				if entry != input[1 + column * n + row] { return -1 }
				if column != row {
					if entry < 0 { off_diagonal_sum -= entry } else { off_diagonal_sum += entry }
				}
				matrix[row * n + column] = f64(entry) / 1_000_000.0
			}
			if diagonal <= off_diagonal_sum { return -1 }
			rhs[row] = f64(input[vector_offset + row]) / 1_000_000.0
			residual[row] = rhs[row]
			direction[row] = rhs[row]
		}
		output_bytes := n * 8
		if output == nil || int(output_capacity) < output_bytes { return -2 }
		mut residual_squared := f64(0)
		for index in 0 .. n { residual_squared += residual[index] * residual[index] }
		for _ in 0 .. max_iterations {
			if residual_squared <= 1.0e-10 * 1.0e-10 { break }
			for row in 0 .. n {
				product[row] = 0
				for column in 0 .. n { product[row] += matrix[row * n + column] * direction[column] }
			}
			mut denominator := f64(0)
			for index in 0 .. n { denominator += direction[index] * product[index] }
			if denominator <= 0 { return -1 }
			alpha := residual_squared / denominator
			for index in 0 .. n {
				solution[index] += alpha * direction[index]
				residual[index] -= alpha * product[index]
			}
			mut next_residual_squared := f64(0)
			for index in 0 .. n { next_residual_squared += residual[index] * residual[index] }
			if next_residual_squared <= 1.0e-10 * 1.0e-10 {
				residual_squared = next_residual_squared
				break
			}
			beta := next_residual_squared / residual_squared
			for index in 0 .. n { direction[index] = residual[index] + beta * direction[index] }
			residual_squared = next_residual_squared
		}
		for index in 0 .. n { write_f64_le(mut output, index * 8, solution[index]) }
		return i64(output_bytes)
	}
}
