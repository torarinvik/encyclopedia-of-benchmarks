module unscented_kalman_filter

import math

const bad = -1.0e300

fn sigma_points(x f64, y f64, p00 f64, p01 f64, p11 f64, mut points [10]f64) bool {
	l00 := math.sqrt(2.0 * p00)
	if l00 <= 0.0 { return false }
	l10 := (2.0 * p01) / l00
	remainder := 2.0 * p11 - l10 * l10
	if remainder <= 0.0 { return false }
	l11 := math.sqrt(remainder)
	points[0] = x
	points[1] = y
	points[2] = x + l00
	points[3] = y + l10
	points[4] = x
	points[5] = y + l11
	points[6] = x - l00
	points[7] = y - l10
	points[8] = x
	points[9] = y - l11
	return true
}

@[export: 'unscented_kalman_filter']
pub fn unscented_kalman_filter(v &i64, n usize) f64 {
	if unsafe { v == nil } || n < 10 || n > 17 { return bad }
	steps := unsafe { v[0] }
	if steps < 1 || steps > 8 || n != usize(9 + steps) { return bad }
	if unsafe { v[1] } < -1000 || unsafe { v[1] } > 1000 || unsafe { v[2] } < -1000 || unsafe { v[2] } > 1000 { return bad }
	if unsafe { v[3] } < 500 || unsafe { v[3] } > 1000 || unsafe { v[4] } < -100 || unsafe { v[4] } > 100 || unsafe { v[5] } < 500 || unsafe { v[5] } > 1000 { return bad }
	if unsafe { v[6] } < 10 || unsafe { v[6] } > 50 || unsafe { v[7] } < 10 || unsafe { v[7] } > 50 || unsafe { v[8] } < 10 || unsafe { v[8] } > 100 { return bad }
	for i in 9 .. n {
		if unsafe { v[i] } < -2000 || unsafe { v[i] } > 2000 { return bad }
	}

	scale := 1000.0
	mut x := f64(unsafe { v[1] }) / scale
	mut y := f64(unsafe { v[2] }) / scale
	mut p00 := f64(unsafe { v[3] }) / scale
	mut p01 := f64(unsafe { v[4] }) / scale
	mut p11 := f64(unsafe { v[5] }) / scale
	q0 := f64(unsafe { v[6] }) / scale
	q1 := f64(unsafe { v[7] }) / scale
	noise := f64(unsafe { v[8] }) / scale
	for t in 0 .. int(steps) {
		mut sigma := [10]f64{}
		if !sigma_points(x, y, p00, p01, p11, mut sigma) { return bad }
		mut propagated := [10]f64{}
		for i in 0 .. 5 {
			sx, sy := sigma[i * 2], sigma[i * 2 + 1]
			propagated[i * 2] = sx + 0.1 * sy
			propagated[i * 2 + 1] = sy + 0.05 * sx * sx
		}
		mut mean_x := 0.0
		mut mean_y := 0.0
		for i in 1 .. 5 {
			mean_x += 0.25 * propagated[i * 2]
			mean_y += 0.25 * propagated[i * 2 + 1]
		}
		dx0, dy0 := propagated[0] - mean_x, propagated[1] - mean_y
		mut next_p00, mut next_p01, mut next_p11 := 2.0 * dx0 * dx0, 2.0 * dx0 * dy0, 2.0 * dy0 * dy0
		for i in 1 .. 5 {
			dx, dy := propagated[i * 2] - mean_x, propagated[i * 2 + 1] - mean_y
			next_p00 += 0.25 * dx * dx
			next_p01 += 0.25 * dx * dy
			next_p11 += 0.25 * dy * dy
		}
		x, y = mean_x, mean_y
		p00, p01, p11 = next_p00 + q0, 0.5 * (next_p01 + next_p01), next_p11 + q1

		if !sigma_points(x, y, p00, p01, p11, mut sigma) { return bad }
		mut mapped := [5]f64{}
		for i in 0 .. 5 { mapped[i] = 0.05 * sigma[i * 2] * sigma[i * 2] + sigma[i * 2 + 1] }
		mut expected_z := 0.0
		for i in 1 .. 5 { expected_z += 0.25 * mapped[i] }
		mut innovation, mut cross0, mut cross1 := noise, 0.0, 0.0
		for i in 0 .. 5 {
			weight := if i == 0 { 2.0 } else { 0.25 }
			dx, dy, dz := sigma[i * 2] - x, sigma[i * 2 + 1] - y, mapped[i] - expected_z
			innovation += weight * dz * dz
			cross0 += weight * dx * dz
			cross1 += weight * dy * dz
		}
		if innovation <= 0.0 { return bad }
		k0, k1 := cross0 / innovation, cross1 / innovation
		residual := f64(unsafe { v[9 + t] }) / scale - expected_z
		x += k0 * residual
		y += k1 * residual
		u0, u1, old_p01 := k0 * innovation, k1 * innovation, p01
		p00 -= u0 * k0
		p01 = old_p01 - 0.5 * (u0 * k1 + u1 * k0)
		p11 -= u1 * k1
	}
	return x
}
