module runge_kutta

import math

const invalid_result = -1.0e300
fn derivative(id i64, x f64, y f64) f64 {
	match id { 0 { return y } 1 { return x } 2 { return x + y } 3 { return (x - y) / 2.0 } else { return 1.0 + y * y } }
}
fn rk4_step(id i64, x f64, y f64, h f64) (f64, bool) {
	k1 := derivative(id, x, y)
	k2 := derivative(id, x + 0.5 * h, y + 0.5 * h * k1)
	k3 := derivative(id, x + 0.5 * h, y + 0.5 * h * k2)
	k4 := derivative(id, x + h, y + h * k3)
	out := y + (1.0 / 6.0) * h * (k1 + 2.0 * k2 + 2.0 * k3 + k4)
	return out, k1.is_finite() && k2.is_finite() && k3.is_finite() && k4.is_finite() && out.is_finite()
}

@[export: 'runge_kutta']
pub fn runge_kutta(input &i64, length usize) f64 {
	if unsafe { input == nil } || length != 5 { return invalid_result }
	unsafe {
		fid, ym, xm, hm, em := input[0], input[1], input[2], input[3], input[4]
		if fid < 0 || fid > 4 || ym < -1000000 || ym > 1000000 || xm < -1000000 || xm > 1000000 || em < -1000000 || em > 1000000 || hm < 10000 || hm > 250000 || em <= xm { return invalid_result }
		y0, x0, h, ending := f64(ym) / 1000000.0, f64(xm) / 1000000.0, f64(hm) / 1000000.0, f64(em) / 1000000.0
		if fid == 4 && (x0 < 0.0 || y0 > 0.0) { return invalid_result }
		steps := int(math.ceil((ending - x0) / h))
		if steps < 1 || steps > 64 { return invalid_result }
		mut x, mut y := x0, y0
		for _ in 0 .. steps {
			next, ok := rk4_step(fid, x, y, h)
			if !ok { return invalid_result }
			y = next; x += h
			if !x.is_finite() { return invalid_result }
		}
		return y
	}
}
