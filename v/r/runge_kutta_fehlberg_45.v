module runge_kutta_fehlberg_45

import math

const invalid_result = -1.0e300
fn derivative(id i64, x f64, y f64) f64 {
	match id { 0 { return y } 1 { return x } 2 { return x + y } 3 { return (x - y) / 2.0 } else { return 1.0 + y * y } }
}
fn fehlberg_step(id i64, x f64, y f64, h f64) (f64, bool) {
	k1 := h * derivative(id, x, y)
	k2 := h * derivative(id, x + h / 4.0, y + k1 / 4.0)
	k3 := h * derivative(id, x + (3.0 / 8.0) * h, y + (3.0 / 32.0) * k1 + (9.0 / 32.0) * k2)
	k4 := h * derivative(id, x + (12.0 / 13.0) * h, y + (1932.0 / 2197.0) * k1 - (7200.0 / 2197.0) * k2 + (7296.0 / 2197.0) * k3)
	k5 := h * derivative(id, x + h, y + (439.0 / 216.0) * k1 - 8.0 * k2 + (3680.0 / 513.0) * k3 - (845.0 / 4104.0) * k4)
	k6 := h * derivative(id, x + h / 2.0, y - (8.0 / 27.0) * k1 + 2.0 * k2 - (3544.0 / 2565.0) * k3 + (1859.0 / 4104.0) * k4 - (11.0 / 40.0) * k5)
	out := y + (16.0 / 135.0) * k1 + (6656.0 / 12825.0) * k3 + (28561.0 / 56430.0) * k4 - (9.0 / 50.0) * k5 + (2.0 / 55.0) * k6
	return out, k1.is_finite() && k2.is_finite() && k3.is_finite() && k4.is_finite() && k5.is_finite() && k6.is_finite() && out.is_finite()
}

@[export: 'runge_kutta_fehlberg_45']
pub fn runge_kutta_fehlberg_45(input &i64, length usize) f64 {
	if unsafe { input == nil } || length != 5 { return invalid_result }
	unsafe {
		fid, ym, xm, hm, em := input[0], input[1], input[2], input[3], input[4]
		if fid < 0 || fid > 4 || ym < -1000000 || ym > 1000000 || xm < -1000000 || xm > 1000000 || em < -1000000 || em > 1000000 || hm < 10000 || hm > 250000 || em <= xm { return invalid_result }
		y0, x0, h, ending := f64(ym) / 1000000.0, f64(xm) / 1000000.0, f64(hm) / 1000000.0, f64(em) / 1000000.0
		if fid == 4 && (x0 < 0.0 || y0 > 0.0) { return invalid_result }
		steps := int((ending - x0) / h)
		if steps < 1 || steps > 64 { return invalid_result }
		mut x, mut y := x0, y0
		for _ in 0 .. steps {
			next, ok := fehlberg_step(fid, x, y, h)
			if !ok { return invalid_result }
			y = next; x = h + x
			if !x.is_finite() { return invalid_result }
		}
		return y
	}
}
