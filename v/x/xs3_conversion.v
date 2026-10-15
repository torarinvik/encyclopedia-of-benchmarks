module xs3_conversion

@[export: 'xs3_conversion']
pub fn xs3_conversion(packed &i64, length usize) i64 {
	if length != 2 { return -1 }
	direction := unsafe { packed[0] }
	mut value := unsafe { packed[1] }
	if direction == 0 {
		if value < 0 || value > 2147483647 { return -1 }
	mut decoded := i64(0)
	mut multiplier := i64(1)
	for value > 0 {
		nibble := value & 15
		if nibble < 3 || nibble > 12 { return -1 }
		decoded += (nibble - 3) * multiplier
		multiplier *= 10
		value >>= 4
	}
	return decoded
	}
	if direction == 1 {
		if value < 0 || value > 9999999 { return -1 }
		mut encoded := i64(0)
		mut shift := u32(0)
		for value > 0 {
			digit := value % 10 + 3
			encoded |= digit << (shift * 4)
			value /= 10
			shift++
		}
		return encoded
	}
	return -1
}
