import math

const max_dimension = 8
const max_matrix_micro = 1_000_000_000
const max_vector_micro = 1_000_000_000
const max_spectral_micro = 1_000_000_000
const max_iterations = 1000

fn write_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.f64_bits(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'chebyshev_iteration']
pub fn chebyshev_iteration(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > usize(1 + max_dimension * max_dimension + 2 * max_dimension + 4) { return -1 }
		if values[0] < 1 || values[0] > max_dimension { return -1 }
		n := int(values[0])
		if int(length) != 1 + n * n + 2 * n + 4 { return -1 }
		matrix_end := 1 + n * n
		vector_end := matrix_end + 2 * n
		mut matrix := [64]f64{}
		mut b := [8]f64{}
		mut x := [8]f64{}
		mut residual := [8]f64{}
		mut direction := [8]f64{}
		for index in 0 .. n * n {
			value := values[index + 1]
			if value < -max_matrix_micro || value > max_matrix_micro { return -1 }
			matrix[index] = f64(value) / 1_000_000.0
		}
		for index in 0 .. n {
			rhs := values[matrix_end + index]
			guess := values[matrix_end + n + index]
			if rhs < -max_vector_micro || rhs > max_vector_micro || guess < -max_vector_micro || guess > max_vector_micro { return -1 }
			b[index] = f64(rhs) / 1_000_000.0
			x[index] = f64(guess) / 1_000_000.0
		}
		min_micro := values[vector_end]
		max_micro := values[vector_end + 1]
		iterations := values[vector_end + 2]
		tolerance_micro := values[vector_end + 3]
		if min_micro < 1 || max_micro <= min_micro || max_micro > max_spectral_micro || iterations < 1 || iterations > max_iterations || tolerance_micro < 1 || tolerance_micro > max_vector_micro { return -1 }
		min_eigenvalue := f64(min_micro) / 1_000_000.0
		max_eigenvalue := f64(max_micro) / 1_000_000.0
		tolerance := f64(tolerance_micro) / 1_000_000.0
		output_bytes := n * 8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }

		for row in 0 .. n {
			mut product := 0.0
			for column in 0 .. n { product += matrix[row * n + column] * x[column] }
			residual[row] = b[row] - product
		}
		d := (max_eigenvalue + min_eigenvalue) / 2.0
		c := (max_eigenvalue - min_eigenvalue) / 2.0
		mut alpha := 0.0
		mut alpha_previous := 0.0
		for iteration in 0 .. int(iterations) {
			mut squares := 0.0
			for index in 0 .. n { squares += residual[index] * residual[index] }
			if math.sqrt(squares) < tolerance { break }
			if iteration == 0 {
				alpha = 1.0 / d
				for index in 0 .. n { direction[index] = residual[index] }
			} else {
				half_step := c * alpha_previous / 2.0
				beta := half_step * half_step
				alpha = 1.0 / (d - beta / alpha_previous)
				direction_scale := beta / alpha_previous
				for index in 0 .. n { direction[index] = residual[index] + direction_scale * direction[index] }
			}
			for index in 0 .. n { x[index] += alpha * direction[index] }
			for row in 0 .. n {
				mut product := 0.0
				for column in 0 .. n { product += matrix[row * n + column] * x[column] }
				residual[row] = b[row] - product
			}
			alpha_previous = alpha
		}
		for index in 0 .. n { write_f64_le(mut output, index * 8, x[index]) }
		return i64(output_bytes)
	}
}
