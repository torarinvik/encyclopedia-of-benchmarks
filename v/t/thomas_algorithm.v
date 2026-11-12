module thomas_algorithm

import math

const max_n = 32

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'thomas_algorithm']
pub fn thomas_algorithm(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 5 || length > usize(1 + 4 * max_n) { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 1 || n_value > max_n { return -1 }
	n := int(n_value)
	if length != usize(1 + 4 * n) { return -1 }

	mut lower := []i64{len: max_n}
	mut diagonal := []i64{len: max_n}
	mut upper := []i64{len: max_n}
	mut rhs := []i64{len: max_n}
	for row in 0 .. n {
		lower[row] = unsafe { input[1 + row] }
		diagonal[row] = unsafe { input[1 + n + row] }
		upper[row] = unsafe { input[1 + 2 * n + row] }
		rhs[row] = unsafe { input[1 + 3 * n + row] }
	}
	if lower[0] != 0 || upper[n - 1] != 0 { return -1 }
	for row in 0 .. n {
		if lower[row] < -16 || lower[row] > 16 || upper[row] < -16 || upper[row] > 16 { return -1 }
		if diagonal[row] < 17 || diagonal[row] > 64 || rhs[row] < -1000 || rhs[row] > 1000 { return -1 }
		lower_abs := if lower[row] < 0 { -lower[row] } else { lower[row] }
		upper_abs := if upper[row] < 0 { -upper[row] } else { upper[row] }
		if diagonal[row] <= lower_abs + upper_abs { return -1 }
	}
	output_bytes := n * 8
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }

	mut modified_upper := []f64{len: max_n}
	mut modified_rhs := []f64{len: max_n}
	mut solution := []f64{len: max_n}
	modified_upper[0] = f64(upper[0]) / f64(diagonal[0])
	modified_rhs[0] = f64(rhs[0]) / f64(diagonal[0])
	for row in 1 .. n {
		pivot := f64(diagonal[row]) - f64(lower[row]) * modified_upper[row - 1]
		if row + 1 < n { modified_upper[row] = f64(upper[row]) / pivot }
		modified_rhs[row] = (f64(rhs[row]) - f64(lower[row]) * modified_rhs[row - 1]) / pivot
	}
	solution[n - 1] = modified_rhs[n - 1]
	for rev in 0 .. n - 1 {
		row := n - 2 - rev
		solution[row] = modified_rhs[row] - modified_upper[row] * solution[row + 1]
	}
	for row in 0 .. n { put_f64_le(mut output, row * 8, solution[row]) }
	return i64(output_bytes)
}
