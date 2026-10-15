package fast_inverse_sqrt_java_check

import "core:math"

@(export)
fast_inverse_sqrt_java_check :: proc "c" (input: [^]i64, length: uintptr) -> i64 {
	if input == nil || length != 2 do return -1
	if input[0] == 0 {
		if input[1] < 0x00800000 || input[1] > 0x7f7fffff do return -1
		bits := u32(input[1])
		number := transmute(f32)bits
		xhalf := f32(0.5) * number
		seed := u32(0x5f3759df) - (bits >> 1)
		x := transmute(f32)seed
		x = x * (f32(1.5) - xhalf * x * x)
		expected := f32(1.0) / f32(math.sqrt(f64(number)))
		return 1 if x == expected else 0
	}
	if input[0] == 1 {
		if input[1] < 0x0010000000000000 || input[1] > 0x7fefffffffffffff do return -1
		bits := u64(input[1])
		number := transmute(f64)bits
		xhalf := 0.5 * number
		seed := u64(0x5fe6ec85e7de30da) - (bits >> 1)
		x := transmute(f64)seed
		for iteration := 0; iteration < 4; iteration += 1 { x = x * (1.5 - xhalf * x * x) }
		x *= number
		return 1 if x == 1.0 / math.sqrt(number) else 0
	}
	return -1
}
