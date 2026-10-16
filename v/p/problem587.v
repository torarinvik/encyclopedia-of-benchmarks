module problem587

import math

const invalid_result = -1.0e300
const min_fraction = 0.001
const max_fraction = 0.1
const max_n = 100000
const pi_value = 3.141592653589793238462643383279502884

fn circle_bottom_arc_integral(point f64) f64 {
	return ((1.0 - 2.0 * point) * math.sqrt(point - point * point) +
		2.0 * point + math.asin(math.sqrt(1.0 - point))) / 4.0
}

fn concave_triangle_area(n i64) f64 {
	circles := f64(n)
	intersection_y := (circles + 1.0 - math.sqrt(2.0 * circles)) /
		(2.0 * (circles * circles + 1.0))
	intersection_x := circles * intersection_y
	triangle_area := intersection_x * intersection_y / 2.0
	concave_region_area := circle_bottom_arc_integral(0.5) - circle_bottom_arc_integral(intersection_x)
	return triangle_area + concave_region_area
}

@[export: 'problem587']
pub fn problem587(fraction f64) f64 {
	if fraction != fraction || fraction < min_fraction || fraction > max_fraction { return invalid_result }
	l_section_area := (1.0 - pi_value / 4.0) / 4.0
	for n := i64(1); n <= max_n; n++ {
		if concave_triangle_area(n) / l_section_area < fraction { return f64(n) }
	}
	return invalid_result
}
