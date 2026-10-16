import math
@[export: 'scaled_exponential_linear_unit']
pub fn scaled_exponential_linear_unit(values &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { values == nil } || length < 3 || length > 259 { return -1 }
	n := int(unsafe { values[0] })
	if n < 0 || n > 256 || length != usize(n+3) || unsafe { values[1] < -10000000 || values[1] > 10000000 || values[2] < -10000000 || values[2] > 10000000 } { return -1 }
	for i in 0 .. n { if unsafe { values[i+3] < -20000000 || values[i+3] > 20000000 } { return -1 } }
	bytes := n*8
	if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
	alpha := f64(unsafe { values[1] })/1e6; lambda := f64(unsafe { values[2] })/1e6
	for i in 0 .. n {
		x := f64(unsafe { values[i+3] })/1e6
		y := lambda * (if x > 0.0 { x } else { alpha * (math.exp(x)-1.0) })
		bits := u64(i64(math.floor(y*1e9+0.5)))
		for b in 0 .. 8 { unsafe { output[i*8+b] = u8((bits >> (8*b)) & 255) } }
	}
	return i64(bytes)
}
