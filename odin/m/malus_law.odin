package malus_law

import "core:c"
import "core:math"

PI :: 3.141592653589793238462643383279502884

@(export)
malus_law :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return -1.0e300
	initial_intensity := values[0]
	angle := values[1]
	if initial_intensity < 0 || initial_intensity > 1000 || angle < 0 || angle > 360 do return -1.0e300
	radians := (f64(angle) * PI) / 180.0
	cosine := math.cos(radians)
	return f64(initial_intensity) * (cosine * cosine)
}
