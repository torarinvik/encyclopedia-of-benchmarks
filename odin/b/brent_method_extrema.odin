package brent_method_extrema

import "core:math"

EPSILON :: 1.4901161193847656e-8
PI :: 3.141592653589793238462643383279502884
TWO_PI :: 2.0 * PI
THREE_PI :: 3.0 * PI

absolute :: proc(value: f64) -> f64 {
	if value < 0.0 do return -value
	return value
}

objective_value :: proc(x, objective_id: f64) -> f64 {
	if objective_id == 0.0 {
		offset := x - 2.0
		return offset * offset
	}
	if objective_id == 0.5 do return math.cos(x)
	return -math.cos(x)
}

has_valid_bracket :: proc(low, high, objective_id: f64) -> bool {
	if objective_id == 0.0 do return low < 2.0 && 2.0 < high
	if objective_id == 0.5 do return low >= 0.0 && high <= TWO_PI && low < PI && PI < high
	return objective_id == 1.0 && low >= PI && high <= THREE_PI && low < TWO_PI && TWO_PI < high
}

@(export)
brent_method_extrema :: proc "c" (start, ending, objective_id: f64) -> f64 {
	if start != start || ending != ending || objective_id != objective_id ||
		start < -10.0 || start > 10.0 || ending < -10.0 || ending > 10.0 do return -1.0
	a := start
	b := ending
	if a > b {
		swap := a
		a = b
		b = swap
	}
	if b - a <= EPSILON ||
		(objective_id != 0.0 && objective_id != 0.5 && objective_id != 1.0) ||
		!has_valid_bracket(a, b, objective_id) do return -1.0

	golden_ratio := (3.0 - math.sqrt(5.0)) / 2.0
	v := a + golden_ratio * (b - a)
	w := v
	x := v
	fv := objective_value(v, objective_id)
	fw := fv
	fx := fv
	p := 0.0
	q := 0.0
	r := 0.0
	d := 0.0
	e := 0.0

	for iteration := 0; iteration < 256; iteration += 1 {
		midpoint := (a + b) / 2.0
		tolerance := EPSILON * absolute(x)
		tolerance2 := 2.0 * tolerance
		if absolute(e) > tolerance2 {
			r = (x - w) * (fx - fv)
			q = (x - v) * (fx - fw)
			p = (x - v) * q - (x - w) * r
			q = 2.0 * (q - r)
			if q > 0.0 {
				p = -p
			} else {
				q = -q
			}
			r = e
			e = d
		}
		if absolute(p) < absolute(0.5 * q * r) && p < q * (b - x) {
			d = p / q
			u := x + d
			if u - a < tolerance2 || b - u < tolerance2 {
				if x < midpoint do d = tolerance else do d = -tolerance
			}
		} else {
			if x < midpoint do e = b - x else do e = a - x
			d = golden_ratio * e
		}
		u := d
		if absolute(d) < tolerance {
			if d > 0.0 do u = tolerance else do u = -tolerance
		}
		u += x
		fu := objective_value(u, objective_id)
		if fu <= fx {
			if u < x do b = x else do a = x
			v = w
			fv = fw
			w = x
			fw = fx
			x = u
			fx = fu
		} else {
			if u < x do a = u else do b = u
			if fu <= fw || x == w {
				v = w
				fv = fw
				w = u
				fw = fu
			} else if fu <= fv || v == x || v == w {
				v = u; fv = fu
			}
		}
		if !(absolute(x-midpoint) > tolerance-(b-a)/2.0) do return x
	}
	return x
}
