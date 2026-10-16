module newton_raphson_root

import math

@[export: 'newton_raphson_root']
pub fn newton_raphson_root(x0 f64) f64 {
	if !math.is_finite(x0) || x0 < 1.0 || x0 > 4.0 { return -1e300 }
	mut x := f32(x0)
	for _ in 0 .. 1000 {
		square := x * x
		residual := square - f32(3.0)
		if math.abs(residual) <= f32(1e-6) { return f64(x) }
		derivative := f32(2.0) * x
		if derivative == 0 { return -1e300 }
		quotient := residual / derivative
		x = x - quotient
	}
	return f64(x)
}
