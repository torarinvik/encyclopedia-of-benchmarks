package ideal_gas_law

import "core:c"

// Solve one ideal-gas-law variable using a portable operation selector.
@(export)
ideal_gas_law :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 4 do return -1.0e300
	operation, a, b, c := values[0], values[1], values[2], values[3]
	if operation < 0 || operation > 3 || a < 0 || a > 1000 || b < 0 || b > 1000 || c < 0 || c > 1000 do return -1.0e300
	if operation == 0 || operation == 1 {
		if c == 0 do return -1.0e300
		return (f64(a) * f64(b) * 8.314462) / f64(c)
	}
	if a == 0 do return -1.0e300
	return (f64(c) * f64(b)) / (f64(a) * 8.314462)
}
