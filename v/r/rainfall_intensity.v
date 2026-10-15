module rainfall_intensity

import math

@[export: 'rainfall_intensity']
pub fn rainfall_intensity(values &i64, length usize) f64 {
	if length != 6 { return -1.0e300 }
	k := unsafe { values[0] }
	a := unsafe { values[1] }
	b := unsafe { values[2] }
	c := unsafe { values[3] }
	period := unsafe { values[4] }
	duration := unsafe { values[5] }
	if k < 1 || k > 1000 || a < 1 || a > 3 || b < 1 || b > 100 || c < 1 || c > 3 || period < 1 || period > 100 || duration < 1 || duration > 1000 { return -1.0e300 }
	return (f64(k) * math.pow(f64(period), f64(a))) / math.pow(f64(duration + b), f64(c))
}
