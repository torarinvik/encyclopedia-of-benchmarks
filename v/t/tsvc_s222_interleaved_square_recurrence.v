module tsvc_s222_interleaved_square_recurrence

import math

fn seed_ok(x f64) bool { return x == -1 || x == -0.5 || x == 0 || x == 0.5 || x == 1 }

@[export: 'tsvc_s222_interleaved_square_recurrence']
pub fn tsvc_s222_interleaved_square_recurrence(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length < 5 || length > 257 { return -1 }
	unsafe {
		rn := input[0]
		if !rn.is_finite() || math.trunc(rn) != rn || rn < 1 || rn > 64 { return -1 }
		n := int(rn)
		if length != usize(1+4*n) { return -1 }
		for i in 1 .. 1+3*n {
			if !input[i].is_finite() || math.trunc(input[i]) != input[i] || math.abs(input[i]) > 2 { return -1 }
		}
		for i in 1+3*n .. int(length) {
			if !input[i].is_finite() || !seed_ok(input[i]) { return -1 }
		}
		required := 2*n
		if output == nil || capacity < usize(required) { return -2 }
		mut a := [64]f64{}
		mut e := [64]f64{}
		for i in 0 .. n { a[i]=input[1+i]; e[i]=input[1+3*n+i] }
		for i in 1 .. n {
			product := input[1+n+i]*input[1+2*n+i]
			a[i]=a[i]+product
			e[i]=e[i-1]*e[i-1]
			a[i]=a[i]-product
		}
		for i in 0 .. n { output[i]=a[i]; output[n+i]=e[i] }
		return i64(required)
	}
}
