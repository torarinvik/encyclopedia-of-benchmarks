module center_of_mass

const invalid_result = -1.0e300
const max_particles = 64
const max_coordinate_units = i64(1_000_000)
const max_mass_units = i64(1_000_000)

// Round the exact binary64 input to cents, matching Python round(value, 2).
fn round_two_python(value f64) f64 {
	if value == 0.0 { return value }
	negative := value < 0.0
	mut normalized := if negative { -value } else { value }
	mut exponent := 0
	for normalized >= 1.0 { normalized *= 0.5; exponent++ }
	for normalized < 0.5 { normalized *= 2.0; exponent-- }
	significand := u64(normalized * 9_007_199_254_740_992.0)
	numerator := significand * u64(100)
	shift := 53 - exponent
	mut cents := u64(0)
	if shift < 0 { cents = numerator << u32(-shift) }
	else if shift == 0 { cents = numerator }
	else if shift < 64 {
		denominator := u64(1) << u32(shift)
		cents = numerator >> u32(shift)
		remainder := numerator & (denominator - 1)
		half := denominator >> 1
		if remainder > half || (remainder == half && (cents & u64(1)) != 0) { cents++ }
	}
	rounded := f64(cents) / 100.0
	if negative { return -rounded }
	return rounded
}

@[export: 'center_of_mass']
pub fn center_of_mass(values &i64, length usize) f64 {
	if length < 2 || length > 258 { return invalid_result }
	unsafe {
		if values == nil { return invalid_result }
		selector := values[0]
		count_value := values[1]
		if selector < 0 || selector > 2 || count_value < 1 || count_value > max_particles ||
			length != usize(2 + 4 * count_value) { return invalid_result }
		count := int(count_value)
		for index in 0 .. count {
			offset := 2 + 4 * index
			for coordinate in 0 .. 3 {
				unit := values[offset + coordinate]
				if unit < -max_coordinate_units || unit > max_coordinate_units { return invalid_result }
			}
			mass := values[offset + 3]
			if mass < 1 || mass > max_mass_units { return invalid_result }
		}
		mut total_mass := 0.0
		for index in 0 .. count { total_mass += f64(values[2 + 4 * index + 3]) / 1000.0 }
		mut weighted_coordinate := 0.0
		for index in 0 .. count {
			offset := 2 + 4 * index
			coordinate := f64(values[offset + int(selector)]) / 1000.0
			mass := f64(values[offset + 3]) / 1000.0
			weighted_coordinate += coordinate * mass
		}
		return round_two_python(weighted_coordinate / total_mass)
	}
}
