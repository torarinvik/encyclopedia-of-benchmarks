module tsvc_s451_sincos_vector_map

import math

@[export: 'tsvc_s451_sincos_vector_map']
pub fn tsvc_s451_sincos_vector_map(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 129 { return -1 }
	unsafe {
		rn := input[0]
		if !rn.is_finite() || math.trunc(rn) != rn || rn < 1 || rn > 64 { return -1 }
		n := int(rn)
		if length != usize(1 + 2*n) { return -1 }
		for i in 1 .. int(length) {
			if !input[i].is_finite() || math.abs(input[i]) > 10 { return -1 }
		}
		if output == nil || capacity < usize(n) { return -2 }
		for i in 0 .. n { output[i] = math.sin(input[1+i]) + math.cos(input[1+n+i]) }
		return i64(n)
	}
}
