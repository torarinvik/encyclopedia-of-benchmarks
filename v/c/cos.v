module cos

import math

@[export: 'cos']
pub fn cos(x_value f64) f64 {
	if !(x_value >= -1000000.0 && x_value <= 1000000.0) { return -1.0 }
	tp := 1.0 / (2.0 * 3.141592653589793)
	mut x := x_value * tp
	x -= 0.25 + math.floor(x + 0.25)
	x *= 16.0 * (math.abs(x) - 0.5)
	x += 0.225 * x * (math.abs(x) - 1.0)
	return x
}
