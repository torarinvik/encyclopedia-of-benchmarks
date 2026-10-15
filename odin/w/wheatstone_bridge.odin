package wheatstone_bridge

import "core:c"

@(export)
wheatstone_bridge :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return -1.0e300
	resistance_1 := values[0]
	resistance_2 := values[1]
	resistance_3 := values[2]
	if resistance_1 < 1 || resistance_1 > 1_000_000 || resistance_2 < 1 || resistance_2 > 1_000_000 || resistance_3 < 1 || resistance_3 > 1_000_000 do return -1.0e300
	return (f64(resistance_2) / f64(resistance_1)) * f64(resistance_3)
}
