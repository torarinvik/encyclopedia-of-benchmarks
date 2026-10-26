module tsvc_s275_column_conditional_axpy_recurrence

import math

const max_n = 8

@[export: 'tsvc_s275_column_conditional_axpy_recurrence']
pub fn tsvc_s275_column_conditional_axpy_recurrence(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 193 { return -1 }
	unsafe {
		rn := input[0]
		if !rn.is_finite() || math.trunc(rn) != rn || rn < 1 || rn > f64(max_n) { return -1 }
		n := int(rn)
		cells := n * n
		if length != usize(1 + 3*cells) { return -1 }
		for i in 1 .. int(length) {
			if !input[i].is_finite() || math.trunc(input[i]) != input[i] || math.abs(input[i]) > 16 { return -1 }
		}
		if output == nil || capacity < usize(cells) { return -2 }
		mut a := [max_n * max_n]f64{}
		for i in 0 .. cells { a[i] = input[1+i] }
		bs := 1 + cells
		cs := 1 + 2*cells
		for col in 0 .. n {
			if a[col] > 0 {
				for row in 1 .. n {
					index := row*n + col
					a[index] = a[index-n] + input[bs+index] * input[cs+index]
				}
			}
		}
		for i in 0 .. cells { output[i] = a[i] }
		return i64(cells)
	}
}
