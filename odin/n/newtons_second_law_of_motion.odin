package newtons_second_law_of_motion

import "core:c"

@(export)
newtons_second_law_of_motion :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return -1.0e300
	mass := values[0]
	acceleration := values[1]
	if mass < -1000 || mass > 1000 || acceleration < -1000 || acceleration > 1000 do return -1.0e300
	return f64(mass) * f64(acceleration)
}
