package speed_of_sound

import "core:c"
import "core:math"

@(export)
speed_of_sound :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return -1.0e300
	density := values[0]
	bulk_modulus := values[1]
	if density < 1 || density > 1000 || bulk_modulus < 1 || bulk_modulus > 1_000_000_000 do return -1.0e300
	return math.pow(f64(bulk_modulus) / f64(density), 0.5)
}
