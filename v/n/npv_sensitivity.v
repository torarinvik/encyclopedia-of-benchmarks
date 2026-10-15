module npv_sensitivity

import math

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for b in 0 .. 8 { unsafe { output[offset+b] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'npv_sensitivity']
pub fn npv_sensitivity(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	unsafe {
		nv, rv := input[0], input[1]
		if nv < 0 || nv > 64 || rv < 0 || rv > 32 { return -1 }
		n, rates := int(nv), int(rv)
		if length != usize(2+n+rates) { return -1 }
		for t in 0 .. n { if input[2+t] < -1000000 || input[2+t] > 1000000 { return -1 } }
		for r in 0 .. rates { if input[2+n+r] < 0 || input[2+n+r] > 1000 { return -1 } }
		if capacity < rates*8 || (rates > 0 && output == nil) { return -2 }
		for r in 0 .. rates {
			rate := f64(input[2+n+r])/10000.0
			mut total := 0.0
			for t in 0 .. n { term := f64(input[2+t])/math.pow(1.0+rate,f64(t)); total += term }
			put_f64_le(mut output,r*8,total)
		}
		return i64(rates*8)
	}
}
