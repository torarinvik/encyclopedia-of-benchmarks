package resonant_frequency

import "core:c"
import "core:math"

@(export)
resonant_frequency :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return -1.0e300
	inductance := values[0]
	capacitance := values[1]
	if inductance < 1 || inductance > 1000 || capacitance < 1 || capacitance > 1000 do return -1.0e300
	pi: f64 = 3.14159265358979323846
	return 1.0 / (2.0 * pi * math.sqrt(f64(inductance) * f64(capacitance)))
}
