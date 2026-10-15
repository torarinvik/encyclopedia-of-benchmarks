package chebyshev_distance

import "core:c"

// Return the greatest absolute coordinate difference from packed points.
@(export)
chebyshev_distance :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length < 3 do return -1
	dimension_value := values[0]
	if dimension_value < 1 || dimension_value > 128 do return -1
	dimension := c.size_t(dimension_value)
	if length != 1 + 2 * dimension do return -1
	maximum: i64 = 0
	for i: c.size_t = 0; i < dimension; i += 1 {
		a := values[1 + i]
		b := values[1 + dimension + i]
		if a < -1_000_000_000 || a > 1_000_000_000 || b < -1_000_000_000 || b > 1_000_000_000 do return -1
		difference := a - b
		if difference < 0 do difference = -difference
		if difference > maximum do maximum = difference
	}
	return maximum
}
