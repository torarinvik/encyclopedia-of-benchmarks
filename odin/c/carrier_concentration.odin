package carrier_concentration

import "core:c"
import "core:math"

@(export)
carrier_concentration :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return -1.0e300
	electron_conc := values[0]
	hole_conc := values[1]
	intrinsic_conc := values[2]
	if electron_conc < 0 || electron_conc > 1_000_000 || hole_conc < 0 || hole_conc > 1_000_000 || intrinsic_conc < 0 || intrinsic_conc > 1_000_000 do return -1.0e300
	zero_count := i32(electron_conc == 0) + i32(hole_conc == 0) + i32(intrinsic_conc == 0)
	if zero_count != 1 do return -1.0e300
	if electron_conc == 0 do return f64(intrinsic_conc * intrinsic_conc) / f64(hole_conc)
	if hole_conc == 0 do return f64(intrinsic_conc * intrinsic_conc) / f64(electron_conc)
	return math.pow(f64(electron_conc * hole_conc), 0.5)
}
