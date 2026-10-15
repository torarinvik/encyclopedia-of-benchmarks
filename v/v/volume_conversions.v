module volume_conversions
import math

const MaxValue = 1000
const InvalidResult = i64(-1)

fn unit_factor_to_cubic_meters(unit i64) f64 {
	if unit == 1 { return 0.001 }
	return 1.0
}

fn put_f64_le(mut output &u8, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'volume_conversions']
pub fn volume_conversions(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 3 { return InvalidResult }
	value, from_unit, to_unit := input[0], input[1], input[2]
	if value < 0 || value > MaxValue || from_unit < 0 || from_unit > 2 || to_unit < 0 || to_unit > 2 || from_unit == to_unit {
		return InvalidResult
	}
	if capacity < 8 || unsafe { output == nil } { return -2 }
	cubic_meters := f64(value) * unit_factor_to_cubic_meters(from_unit)
	converted := cubic_meters / unit_factor_to_cubic_meters(to_unit)
	put_f64_le(mut output, converted)
	return 8
}
