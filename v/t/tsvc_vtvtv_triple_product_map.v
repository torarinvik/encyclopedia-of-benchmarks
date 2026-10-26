module tsvc_vtvtv_triple_product_map

import math

@[export: 'tsvc_vtvtv_triple_product_map']
pub fn tsvc_vtvtv_triple_product_map(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > 193 { return -1 }
	unsafe {
		rn := input[0]
		if !rn.is_finite() || math.trunc(rn) != rn || rn < 1 || rn > 64 { return -1 }
		n := int(rn)
		if length != usize(1 + 3*n) { return -1 }
		for i in 1 .. int(length) {
			if !input[i].is_finite() || math.trunc(input[i]) != input[i] || math.abs(input[i]) > 2 { return -1 }
		}
		if output == nil || capacity < usize(n) { return -2 }
		for i in 0 .. n { output[i] = (input[1+i] * input[1+n+i]) * input[1+2*n+i] }
		return i64(n)
	}
}
