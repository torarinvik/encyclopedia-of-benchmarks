package rotate_left32

// Rotate a 32-bit word left and return its unsigned value in i64.
@(export)
rotate_left32 :: proc "c" (value, shift: u64) -> i64 {
	if value > 4_294_967_295 || shift > 2_147_483_647 do return -1
	bits := u32(value)
	amount := u32(shift % 32)
	if amount == 0 do return i64(bits)
	return i64((bits << amount) | (bits >> (32 - amount)))
}
