package pi_approximation

import "core:c"

@(export)
pi_approximation :: proc "contextless" (points: [^]f64, point_count: c.size_t) -> f64 {
	inside: i64 = 0
	for index := 0; index < int(point_count); index += 1 {
		x := points[2 * index]
		y := points[2 * index + 1]
		if x * x + y * y <= 1.0 do inside += 1
	}
	return 4.0 * f64(inside) / f64(point_count)
}
