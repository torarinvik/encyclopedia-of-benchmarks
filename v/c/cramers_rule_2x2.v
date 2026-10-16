module cramers_rule_2x2

import math

const limit = i64(1_000_000)

fn write_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'cramers_rule_2x2']
pub fn cramers_rule_2x2(v &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { v == nil } || length != 6 { return -1 }
	for i in 0 .. 6 {
		value := unsafe { v[i] }
		if value < -limit || value > limit { return -1 }
	}
	a1,b1,c1,a2,b2,c2 := unsafe { v[0],v[1],v[2],v[3],v[4],v[5] }
	d,dx,dy := a1*b2-a2*b1, c1*b2-c2*b1, a1*c2-a2*c1
	if d == 0 { return -1 }
	if unsafe { output == nil } || capacity < 16 { return -2 }
	write_f64_le(mut output, 0, f64(dx)/f64(d))
	write_f64_le(mut output, 8, f64(dy)/f64(d))
	return 2
}
