module gaussian_elimination

import math

fn put_f64_le(output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for b in 0 .. 8 { unsafe { output[offset+b] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'gaussian_elimination']
pub fn gaussian_elimination(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > 8 { return -1 }
		n := int(input[0])
		if length != usize(1+n*n+n) { return -1 }
		mut matrix := [][]f64{len: n, init: []f64{len: 9}}
		for row in 0 .. n {
			for col in 0 .. n {
				value := input[1+row*n+col]
				if (row == col && value != 32) || (row != col && value != 0 && value != -1) { return -1 }
				if (row+1 < col || col+1 < row) && value != 0 { return -1 }
				if row != col && value != input[1+col*n+row] { return -1 }
				matrix[row][col] = f64(value)
			}
			rhs := input[1+n*n+row]
			if rhs < -100 || rhs > 100 { return -1 }
			matrix[row][n] = f64(rhs)
		}
		if output == nil || capacity < usize(n*8) { return -2 }
		for step in 0 .. n-1 {
			for row in step+1 .. n {
				factor := matrix[row][step] / matrix[step][step]
				for col in step .. n+1 { matrix[row][col] -= factor * matrix[step][col] }
			}
		}
		mut solution := []f64{len: n}
		for row := n-1; row >= 0; row-- {
			mut sum := 0.0
			for col in row+1 .. n { sum += matrix[row][col] * solution[col] }
			solution[row] = (matrix[row][n] - sum) / matrix[row][row]
		}
		for i in 0 .. n { put_f64_le(output, i*8, solution[i]) }
		return i64(n*8)
	}
}
