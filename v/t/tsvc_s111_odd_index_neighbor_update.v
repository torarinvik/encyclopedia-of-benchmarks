module tsvc_s111_odd_index_neighbor_update

import math

const max_n = 64

@[export: 'tsvc_s111_odd_index_neighbor_update']
pub fn tsvc_s111_odd_index_neighbor_update(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 129 { return -1 }
	unsafe {
		rn := input[0]
		if !rn.is_finite() || math.trunc(rn) != rn || rn < 1 || rn > f64(max_n) { return -1 }
		n := int(rn)
		if length != usize(1 + 2*n) { return -1 }
		for i in 1 .. int(length) {
			if !input[i].is_finite() || math.trunc(input[i]) != input[i] || math.abs(input[i]) > 1000 { return -1 }
		}
		if output == nil || capacity < usize(n) { return -2 }
		for i in 0 .. n { output[i] = input[1+i] }
		for i in 1 .. n { if i % 2 == 1 { output[i] = input[i] + input[1+n+i] } }
		return i64(n)
	}
}
