module sin_radians

import math

@[export: 'sin_radians']
pub fn sin_radians(radians f64) f64 {
	if !(radians >= -1_000_000.0 && radians <= 1_000_000.0) { return -1.0 }
	mut x := (3.141592653589793 / 2.0) - radians
	tp := 1.0 / (2.0 * 3.141592653589793)
	x *= tp
	x -= 0.25 + math.floor(x + 0.25)
	x *= 16.0 * (math.abs(x) - 0.5)
	x += 0.225 * x * (math.abs(x) - 1.0)
	return x
}
