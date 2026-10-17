package unscented_kalman_filter

import "core:c"
import "core:math"

BAD :: -1.0e300
Sigma_Points :: struct { points: [5][2]f64, valid: bool }

sigma_points :: proc(x, y, p00, p01, p11: f64) -> Sigma_Points {
	result: Sigma_Points
	l00 := math.sqrt(2.0 * p00)
	if l00 <= 0 do return result
	l10 := (2.0 * p01) / l00
	remainder := 2.0 * p11 - l10 * l10
	if remainder <= 0 do return result
	l11 := math.sqrt(remainder)
	result.points[0] = {x, y}
	result.points[1] = {x + l00, y + l10}
	result.points[2] = {x, y + l11}
	result.points[3] = {x - l00, y - l10}
	result.points[4] = {x, y - l11}
	result.valid = true
	return result
}

@(export)
unscented_kalman_filter :: proc "c" (v: [^]i64, n: c.size_t) -> f64 {
	if v == nil || n < 10 || n > 17 do return BAD
	steps := v[0]
	if steps < 1 || steps > 8 || n != c.size_t(9 + steps) do return BAD
	if v[1] < -1000 || v[1] > 1000 || v[2] < -1000 || v[2] > 1000 do return BAD
	if v[3] < 500 || v[3] > 1000 || v[4] < -100 || v[4] > 100 || v[5] < 500 || v[5] > 1000 do return BAD
	if v[6] < 10 || v[6] > 50 || v[7] < 10 || v[7] > 50 || v[8] < 10 || v[8] > 100 do return BAD
	for i := c.size_t(9); i < n; i += 1 {
		if v[i] < -2000 || v[i] > 2000 do return BAD
	}

	scale := 1000.0
	x := f64(v[1]) / scale
	y := f64(v[2]) / scale
	p00 := f64(v[3]) / scale
	p01 := f64(v[4]) / scale
	p11 := f64(v[5]) / scale
	q0 := f64(v[6]) / scale
	q1 := f64(v[7]) / scale
	noise := f64(v[8]) / scale
	for t := i64(0); t < steps; t += 1 {
		start := sigma_points(x, y, p00, p01, p11)
		if !start.valid do return BAD
		propagated: [5][2]f64
		for i := 0; i < 5; i += 1 {
			sx, sy := start.points[i][0], start.points[i][1]
			propagated[i][0] = sx + 0.1 * sy
			propagated[i][1] = sy + 0.05 * sx * sx
		}
		mean_x, mean_y := 0.0, 0.0
		for i := 1; i < 5; i += 1 {
			mean_x += 0.25 * propagated[i][0]
			mean_y += 0.25 * propagated[i][1]
		}
		dx0, dy0 := propagated[0][0] - mean_x, propagated[0][1] - mean_y
		next_p00, next_p01, next_p11 := 2.0 * dx0 * dx0, 2.0 * dx0 * dy0, 2.0 * dy0 * dy0
		for i := 1; i < 5; i += 1 {
			dx, dy := propagated[i][0] - mean_x, propagated[i][1] - mean_y
			next_p00 += 0.25 * dx * dx
			next_p01 += 0.25 * dx * dy
			next_p11 += 0.25 * dy * dy
		}
		x, y = mean_x, mean_y
		p00, p01, p11 = next_p00 + q0, 0.5 * (next_p01 + next_p01), next_p11 + q1

		measurement_points := sigma_points(x, y, p00, p01, p11)
		if !measurement_points.valid do return BAD
		mapped: [5]f64
		for i := 0; i < 5; i += 1 {
			sx, sy := measurement_points.points[i][0], measurement_points.points[i][1]
			mapped[i] = 0.05 * sx * sx + sy
		}
		expected_z := 0.0
		for i := 1; i < 5; i += 1 do expected_z += 0.25 * mapped[i]
		innovation, cross0, cross1 := noise, 0.0, 0.0
		for i := 0; i < 5; i += 1 {
			weight := 0.25
			if i == 0 do weight = 2.0
			dx := measurement_points.points[i][0] - x
			dy := measurement_points.points[i][1] - y
			dz := mapped[i] - expected_z
			innovation += weight * dz * dz
			cross0 += weight * dx * dz
			cross1 += weight * dy * dz
		}
		if innovation <= 0 do return BAD
		k0, k1 := cross0 / innovation, cross1 / innovation
		residual := f64(v[c.size_t(9) + c.size_t(t)]) / scale - expected_z
		x += k0 * residual
		y += k1 * residual
		u0, u1, old_p01 := k0 * innovation, k1 * innovation, p01
		p00 -= u0 * k0
		p01 = old_p01 - 0.5 * (u0 * k1 + u1 * k0)
		p11 -= u1 * k1
	}
	return x
}
