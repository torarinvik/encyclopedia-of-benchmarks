module rotate_right32

// Rotate a 32-bit word right and return its unsigned value in i64.
@[export: 'rotate_right32']
pub fn rotate_right32(value u64, shift u64) i64 {
	if value > u64(4_294_967_295) || shift > u64(2_147_483_647) { return -1 }
	bits := u32(value)
	amount := int(shift % 32)
	if amount == 0 { return i64(bits) }
	return i64((bits >> amount) | (bits << (32 - amount)))
}
