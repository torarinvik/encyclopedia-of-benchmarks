module tsvc_s313_dot_product_reduction

import math

const max_n = 64

@[export: 'tsvc_s313_dot_product_reduction']
pub fn tsvc_s313_dot_product_reduction(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 129 { return -1 }
	unsafe {
		raw_n := input[0]
		if !raw_n.is_finite() || math.trunc(raw_n) != raw_n || raw_n < 1 || raw_n > f64(max_n) { return -1 }
		n := int(raw_n)
		if length != usize(1 + 2*n) { return -1 }
		for i in 1 .. int(length) {
			if !input[i].is_finite() || math.trunc(input[i]) != input[i] || math.abs(input[i]) > 1000 { return -1 }
		}
		if output == nil || capacity < 1 { return -2 }
		mut sum := 0.0
		for i in 0 .. n { sum += input[1+i] * input[1+n+i] }
		output[0] = sum
		return 1
	}
}
