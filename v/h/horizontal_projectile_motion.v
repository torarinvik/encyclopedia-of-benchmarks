module horizontal_projectile_motion

import math

const gravity = 9.80665
const output_bytes = i64(24)

fn round_cents(value f64) i64 {
	bits := math.bits_from_f64(value)
	exponent := int((bits >> 52) & 2047)
	if exponent == 0 { return 0 }
	mantissa := (u64(1) << 52) | (bits & u64(4503599627370495))
	product := mantissa * u64(25)
	right_shift := 1073 - exponent
	if right_shift >= 59 { return 0 }
	mut rounded := product >> u32(right_shift)
	divisor := u64(1) << u32(right_shift)
	remainder := product & (divisor - 1)
	halfway := divisor >> 1
	if remainder > halfway || (remainder == halfway && (rounded & 1) != 0) { rounded++ }
	if (bits >> 63) != 0 { return -i64(rounded) }
	return i64(rounded)
}

fn store_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'horizontal_projectile_motion']
pub fn horizontal_projectile_motion(values &i64, length usize, mut output &u8,
		output_capacity usize) i64 {
	if unsafe { values == nil } || length != 2 { return -1 }
	velocity_milli, angle_millidegrees := unsafe { values[0] }, unsafe { values[1] }
	if velocity_milli < 0 || velocity_milli > 100000 ||
		angle_millidegrees < 1000 || angle_millidegrees > 90000 { return -1 }
	if unsafe { output == nil } || output_capacity < 24 { return -2 }

	velocity := f64(velocity_milli) / 1000.0
	angle := f64(angle_millidegrees) / 1000.0
	pi_over_180 := 3.14159265358979323846264338327950288 / 180.0
	velocity_squared := velocity * velocity
	distance_raw := velocity_squared * math.sin((2.0 * angle) * pi_over_180) / gravity
	angle_sine := math.sin(angle * pi_over_180)
	sine_squared := angle_sine * angle_sine
	height_raw := velocity_squared * sine_squared / (2.0 * gravity)
	time_raw := (2.0 * velocity) * angle_sine / gravity
	store_f64_le(mut output, 0, f64(round_cents(distance_raw)) / 100.0)
	store_f64_le(mut output, 8, f64(round_cents(height_raw)) / 100.0)
	store_f64_le(mut output, 16, f64(round_cents(time_raw)) / 100.0)
	return output_bytes
}
