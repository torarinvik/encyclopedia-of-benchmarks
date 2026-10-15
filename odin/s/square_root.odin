package square_root

import "core:c"

// Newton square root using binary64 arithmetic and a portable initial estimate.
@(export)
square_root :: proc "c" (value: f64) -> f64 {
	if value == 0 do return 0
	estimate := value if value >= 1 else 1.0
	for iteration := 0; iteration < 1100; iteration += 1 {
		next := 0.5 * estimate + 0.5 * (value / estimate)
		if next >= estimate do return estimate
		estimate = next
	}
	return estimate
}
