module modulo_power_of_two

// Java-compatible low-bit mask for a signed 32-bit input and exponent 1..31.
@[export: 'modulo_power_of_two']
pub fn modulo_power_of_two(values &i64, length usize) i64 {
	if length != 2 { return -1 }
	x := unsafe { values[0] }
	exponent := unsafe { values[1] }
	if x < -2_147_483_648 || x > 2_147_483_647 || exponent < 1 || exponent > 31 { return -1 }
	mask := (i64(1) << u32(exponent)) - 1
	return x & mask
}
