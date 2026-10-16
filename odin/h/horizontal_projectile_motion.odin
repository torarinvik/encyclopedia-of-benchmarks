package horizontal_projectile_motion

import "core:c"
import "core:math"

GRAVITY :: f64(9.80665)
OUTPUT_BYTES :: i64(24)

round_cents :: proc(value: f64) -> i64 {
	bits := transmute(u64)value
	exponent := i32((bits >> 52) & 2047)
	if exponent == 0 do return 0
	mantissa := (u64(1) << 52) | (bits & 4503599627370495)
	product := mantissa * u64(25)
	right_shift := 1073 - exponent
	if right_shift >= 59 do return 0
	rounded := product >> u32(right_shift)
	divisor := u64(1) << u32(right_shift)
	remainder := product & (divisor - 1)
	halfway := divisor >> 1
	if remainder > halfway || (remainder == halfway && (rounded & 1) != 0) {
		rounded += 1
	}
	if (bits >> 63) != 0 do return -i64(rounded)
	return i64(rounded)
}

store_f64_le :: proc(output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
horizontal_projectile_motion :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	velocity_milli, angle_millidegrees := values[0], values[1]
	if velocity_milli < 0 || velocity_milli > 100000 ||
		angle_millidegrees < 1000 || angle_millidegrees > 90000 do return -1
	if output == nil || output_capacity < 24 do return -2

	velocity := f64(velocity_milli) / 1000.0
	angle := f64(angle_millidegrees) / 1000.0
	pi_over_180 := 3.14159265358979323846264338327950288 / 180.0
	velocity_squared := velocity * velocity
	distance_raw := velocity_squared * math.sin((2.0 * angle) * pi_over_180) / GRAVITY
	angle_sine := math.sin(angle * pi_over_180)
	sine_squared := angle_sine * angle_sine
	height_raw := velocity_squared * sine_squared / (2.0 * GRAVITY)
	time_raw := (2.0 * velocity) * angle_sine / GRAVITY
	store_f64_le(output, 0, f64(round_cents(distance_raw)) / 100.0)
	store_f64_le(output, 8, f64(round_cents(height_raw)) / 100.0)
	store_f64_le(output, 16, f64(round_cents(time_raw)) / 100.0)
	return OUTPUT_BYTES
}
