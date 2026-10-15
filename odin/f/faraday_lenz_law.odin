package faraday_lenz_law

import "core:c"

@(export)
faraday_lenz_law :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 3 do return i64(-9223372036854775807) - 1
	final_flux, initial_flux, interval := values[0], values[1], values[2]
	if final_flux < -1_000_000_000 || final_flux > 1_000_000_000 ||
			initial_flux < -1_000_000_000 || initial_flux > 1_000_000_000 ||
			interval < 1 || interval > 1_000_000_000 {
		return i64(-9223372036854775807) - 1
	}
	numerator := -(final_flux - initial_flux) * 10
	magnitude := numerator
	if magnitude < 0 { magnitude = -magnitude }
	quotient := magnitude / interval
	remainder := magnitude % interval
	if 2 * remainder > interval || (2 * remainder == interval && quotient % 2 != 0) { quotient += 1 }
	if numerator < 0 { return -quotient }
	return quotient
}
