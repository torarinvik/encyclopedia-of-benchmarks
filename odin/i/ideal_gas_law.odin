package ideal_gas_law

import "core:c"

// Pressure from the ideal gas law: n * T * R / V.
@(export)
ideal_gas_law :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return -1.0e300
	moles := values[0]
	kelvin := values[1]
	volume := values[2]
	if moles < 0 || moles > 1000 || kelvin < 0 || kelvin > 1000 || volume < 1 || volume > 1000 do return -1.0e300
	return (f64(moles) * f64(kelvin) * 8.314462) / f64(volume)
}
