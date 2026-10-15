module bitwisemin

@[export: 'bitwisemin']
pub fn bitwisemin(values &i64, length usize) i64 {
	if length == 0 || length > 4096 { return -1 }
	mut minimum := unsafe { values[0] }
	if minimum < 0 || minimum > 2_147_483_647 { return -1 }
	for index in 1 .. length {
		value := unsafe { values[index] }
		if value < 0 || value > 2_147_483_647 { return -1 }
		difference := minimum - value
		sign := (u32(difference) >> 31) & 1
		keep_minimum := u32(0xFFFF_FFFF) * sign
		minimum = i64((u32(minimum) & keep_minimum) | (u32(value) & ~keep_minimum))
	}
	return minimum
}
