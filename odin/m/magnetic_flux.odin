package magnetic_flux

import "core:c"
import "core:math"

@(export)
magnetic_flux :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return -1.0e300
	magnetic_field := values[0]
	area := values[1]
	angle := values[2]
	if magnetic_field < 0 || magnetic_field > 10_000 || area < 0 || area > 10_000 || (angle != 0 && angle != 60 && angle != 90 && angle != 120 && angle != 180) do return -1.0e300
	pi_value := 3.14159265358979323846
	radians := f64(angle) * (pi_value / 180.0)
	flux := f64(magnetic_field) * f64(area) * math.cos(radians)
	return math.round(flux * 10.0) / 10.0
}
