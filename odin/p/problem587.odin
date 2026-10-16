package problem587

import "core:math"

INVALID_RESULT :: -1.0e300
MIN_FRACTION :: 0.001
MAX_FRACTION :: 0.1
MAX_N :: 100_000
PI_VALUE :: 3.141592653589793238462643383279502884

circle_bottom_arc_integral :: proc(point: f64) -> f64 {
	return ((1.0 - 2.0 * point) * math.sqrt(point - point * point) +
		2.0 * point + math.asin(math.sqrt(1.0 - point))) / 4.0
}

concave_triangle_area :: proc(n: i64) -> f64 {
	circles := f64(n)
	intersection_y := (circles + 1.0 - math.sqrt(2.0 * circles)) /
		(2.0 * (circles * circles + 1.0))
	intersection_x := circles * intersection_y
	triangle_area := intersection_x * intersection_y / 2.0
	concave_region_area := circle_bottom_arc_integral(0.5) - circle_bottom_arc_integral(intersection_x)
	return triangle_area + concave_region_area
}

@(export)
problem587 :: proc "c" (fraction: f64) -> f64 {
	if fraction != fraction || fraction < MIN_FRACTION || fraction > MAX_FRACTION do return INVALID_RESULT
	l_section_area := (1.0 - PI_VALUE / 4.0) / 4.0
	for n := i64(1); n <= MAX_N; n += 1 {
		if concave_triangle_area(n) / l_section_area < fraction do return f64(n)
	}
	return INVALID_RESULT
}
