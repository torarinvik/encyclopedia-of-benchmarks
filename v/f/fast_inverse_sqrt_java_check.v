module fast_inverse_sqrt_java_check

import math

@[export: 'fast_inverse_sqrt_java_check']
pub fn fast_inverse_sqrt_java_check(input &i64, length usize) i64 {
	if isnil(input) || length != 2 { return -1 }
	if unsafe { input[0] } == 0 {
		if unsafe { input[1] } < 0x00800000 || unsafe { input[1] } > 0x7f7fffff { return -1 }
		bits := u32(unsafe { input[1] })
		number := math.f32_from_bits(bits)
		xhalf := f32(0.5) * number
		seed := u32(0x5f3759df) - (bits >> 1)
		mut x := math.f32_from_bits(seed)
		x = x * (f32(1.5) - xhalf * x * x)
		expected := f32(1.0) / f32(math.sqrt(f64(number)))
		return if x == expected { 1 } else { 0 }
	}
	if unsafe { input[0] } == 1 {
		if unsafe { input[1] } < 0x0010000000000000 || unsafe { input[1] } > 0x7fefffffffffffff { return -1 }
		bits := u64(unsafe { input[1] })
		number := math.f64_from_bits(bits)
		xhalf := 0.5 * number
		seed := u64(0x5fe6ec85e7de30da) - (bits >> 1)
		mut x := math.f64_from_bits(seed)
		for _ in 0 .. 4 { x = x * (1.5 - xhalf * x * x) }
		x *= number
		return if x == 1.0 / math.sqrt(number) { 1 } else { 0 }
	}
	-1
}
