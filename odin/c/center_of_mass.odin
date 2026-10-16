package center_of_mass

import "core:c"

INVALID_RESULT :: -1.0e300
MAX_PARTICLES :: 64
MAX_COORDINATE_UNITS :: 1_000_000
MAX_MASS_UNITS :: 1_000_000

// Round the exact binary64 input to cents, matching Python round(value, 2).
round_two_python :: proc "contextless" (value: f64) -> f64 {
	if value == 0.0 do return value
	negative := value < 0.0
	normalized := if negative do -value else value
	exponent := 0
	for normalized >= 1.0 { normalized *= 0.5; exponent += 1 }
	for normalized < 0.5 { normalized *= 2.0; exponent -= 1 }
	significand := u64(normalized * 9_007_199_254_740_992.0)
	numerator := significand * 100
	shift := 53 - exponent
	cents: u64 = 0
	if shift < 0 { cents = numerator << u32(-shift) }
	else if shift == 0 { cents = numerator }
	else if shift < 64 {
		denominator := u64(1) << u32(shift)
		cents = numerator >> u32(shift)
		remainder := numerator & (denominator - 1)
		half := denominator >> 1
		if remainder > half || (remainder == half && cents & 1 != 0) { cents += 1 }
	}
	rounded := f64(cents) / 100.0
	if negative do return -rounded
	return rounded
}

@(export)
center_of_mass :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 2 || length > 258 do return INVALID_RESULT
	selector := values[0]
	count_value := values[1]
	if selector < 0 || selector > 2 || count_value < 1 || count_value > MAX_PARTICLES ||
		length != c.size_t(2 + 4 * count_value) do return INVALID_RESULT
	count := int(count_value)
	for index := 0; index < count; index += 1 {
		offset := 2 + 4 * index
		for coordinate := 0; coordinate < 3; coordinate += 1 {
			unit := values[offset + coordinate]
			if unit < -MAX_COORDINATE_UNITS || unit > MAX_COORDINATE_UNITS do return INVALID_RESULT
		}
		mass := values[offset + 3]
		if mass < 1 || mass > MAX_MASS_UNITS do return INVALID_RESULT
	}
	total_mass: f64 = 0.0
	for index := 0; index < count; index += 1 {
		total_mass += f64(values[2 + 4 * index + 3]) / 1000.0
	}
	weighted_coordinate: f64 = 0.0
	for index := 0; index < count; index += 1 {
		offset := 2 + 4 * index
		coordinate := f64(values[offset + int(selector)]) / 1000.0
		mass := f64(values[offset + 3]) / 1000.0
		weighted_coordinate += coordinate * mass
	}
	return round_two_python(weighted_coordinate / total_mass)
}
