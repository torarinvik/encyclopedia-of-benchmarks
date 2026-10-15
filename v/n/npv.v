module npv

import math

@[export: 'npv']
pub fn npv(input &i64, length usize) f64 {
	if unsafe { input == nil } || length < 2 { return -1e300 }
	unsafe {
		n64 := input[0]
		rate_bp := input[1]
		if n64 < 0 || n64 > 64 || rate_bp < 0 || rate_bp > 1000 || length != usize(n64)+2 { return -1e300 }
		n := int(n64)
		for t in 0 .. n { if input[t+2] < -1000000 || input[t+2] > 1000000 { return -1e300 } }
		rate := f64(rate_bp)/10000.0
		mut total := 0.0
		for t in 0 .. n {
			term := f64(input[t+2])/math.pow(1.0+rate,f64(t))
			total += term
		}
		return total
	}
}
