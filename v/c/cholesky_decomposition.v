module main

import math

const max_dimension = 6
const max_entry_micro = i64(1_000_000_000)

fn write_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'cholesky_decomposition']
pub fn cholesky_decomposition(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || input[0] < 1 || input[0] > max_dimension { return -1 }
		n := int(input[0])
		if int(length) != 1 + n * n { return -1 }
		mut matrix := [36]f64{}
		mut lower := [36]f64{}
		for index in 0 .. n * n {
			scaled := input[index + 1]
			if scaled < -max_entry_micro || scaled > max_entry_micro { return -1 }
			matrix[index] = f64(scaled) / 1_000_000.0
		}
		for row in 0 .. n {
			for column in 0 .. n {
				left := matrix[row * n + column]
				right := matrix[column * n + row]
				if math.abs(left - right) > 1.0e-8 + 1.0e-5 * math.abs(right) { return -1 }
			}
		}
		for row in 0 .. n {
			for column in 0 .. row + 1 {
				mut sum := 0.0
				for index in 0 .. column {
					sum += lower[row * n + index] * lower[column * n + index]
				}
				residual := matrix[row * n + column] - sum
				if row == column {
					if residual <= 0.0 { return -1 }
					lower[row * n + column] = math.sqrt(residual)
				} else {
					lower[row * n + column] = residual / lower[column * n + column]
				}
			}
		}
		output_bytes := n * n * 8
		if usize(output_bytes) > output_capacity || output == nil { return -2 }
		for index in 0 .. n * n { write_f64_le(mut output, index * 8, lower[index]) }
		return i64(output_bytes)
	}
}
