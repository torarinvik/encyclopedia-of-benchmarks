module brent_method_extrema

import math

const epsilon = 1.4901161193847656e-8
const pi64 = 3.141592653589793238462643383279502884
const two_pi = 2.0 * pi64
const three_pi = 3.0 * pi64

fn absolute(value f64) f64 {
	if value < 0.0 { return -value }
	return value
}

fn objective_value(x f64, objective_id f64) f64 {
	if objective_id == 0.0 {
		offset := x - 2.0
		return offset * offset
	}
	if objective_id == 0.5 { return math.cos(x) }
	return -math.cos(x)
}

fn has_valid_bracket(low f64, high f64, objective_id f64) bool {
	if objective_id == 0.0 { return low < 2.0 && 2.0 < high }
	if objective_id == 0.5 { return low >= 0.0 && high <= two_pi && low < pi64 && pi64 < high }
	return objective_id == 1.0 && low >= pi64 && high <= three_pi && low < two_pi && two_pi < high
}

@[export: 'brent_method_extrema']
pub fn brent_method_extrema(start f64, ending f64, objective_id f64) f64 {
	if start != start || ending != ending || objective_id != objective_id ||
		start < -10.0 || start > 10.0 || ending < -10.0 || ending > 10.0 { return -1.0 }
	mut a := start
	mut b := ending
	if a > b {
		swap := a
		a = b
		b = swap
	}
	if b - a <= epsilon ||
		(objective_id != 0.0 && objective_id != 0.5 && objective_id != 1.0) ||
		!has_valid_bracket(a, b, objective_id) { return -1.0 }

	golden_ratio := (3.0 - math.sqrt(5.0)) / 2.0
	mut v := a + golden_ratio * (b - a)
	mut w := v
	mut x := v
	mut fv := objective_value(v, objective_id)
	mut fw := fv
	mut fx := fv
	mut p := 0.0
	mut q := 0.0
	mut r := 0.0
	mut d := 0.0
	mut e := 0.0

	for iteration := 0; iteration < 256; iteration++ {
		midpoint := (a + b) / 2.0
		tolerance := epsilon * absolute(x)
		tolerance2 := 2.0 * tolerance
		if absolute(e) > tolerance2 {
			r = (x - w) * (fx - fv)
			q = (x - v) * (fx - fw)
			p = (x - v) * q - (x - w) * r
			q = 2.0 * (q - r)
			if q > 0.0 { p = -p } else { q = -q }
			r = e
			e = d
		}
		if absolute(p) < absolute(0.5 * q * r) && p < q * (b - x) {
			d = p / q
			u := x + d
			if u - a < tolerance2 || b - u < tolerance2 {
				if x < midpoint { d = tolerance } else { d = -tolerance }
			}
		} else {
			if x < midpoint { e = b - x } else { e = a - x }
			d = golden_ratio * e
		}
		mut u := d
		if absolute(d) < tolerance {
			if d > 0.0 { u = tolerance } else { u = -tolerance }
		}
		u += x
		fu := objective_value(u, objective_id)
		if fu <= fx {
			if u < x { b = x } else { a = x }
			v = w; fv = fw
			w = x; fw = fx
			x = u; fx = fu
		} else {
			if u < x { a = u } else { b = u }
			if fu <= fw || x == w {
				v = w; fv = fw
				w = u; fw = fu
			} else if fu <= fv || v == x || v == w {
				v = u; fv = fu
			}
		}
		if !(absolute(x-midpoint) > tolerance-(b-a)/2.0) { return x }
	}
	return x
}
