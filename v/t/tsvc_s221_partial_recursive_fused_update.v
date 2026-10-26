module tsvc_s221_partial_recursive_fused_update

import math

@[export: 'tsvc_s221_partial_recursive_fused_update']
pub fn tsvc_s221_partial_recursive_fused_update(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length < 5 || length > 257 { return -1 }
	unsafe {
		rn := input[0]
		if !rn.is_finite() || math.trunc(rn) != rn || rn < 1 || rn > 64 { return -1 }
		n := int(rn)
		if length != usize(1 + 4*n) { return -1 }
		for i in 1 .. int(length) {
			if !input[i].is_finite() || math.trunc(input[i]) != input[i] || math.abs(input[i]) > 2 { return -1 }
		}
		required := 2*n
		if output == nil || capacity < usize(required) { return -2 }
		for i in 0 .. n { output[i] = input[1+i]; output[n+i] = input[1+n+i] }
		for i in 1 .. n {
			output[i] = output[i] + input[1+2*n+i] * input[1+3*n+i]
			output[n+i] = (output[n+i-1] + output[i]) + input[1+3*n+i]
		}
		return i64(required)
	}
}
