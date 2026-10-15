module bit_swap

// Swap two 0-based bits in a signed 32-bit value.
@[export: 'bit_swap']
pub fn bit_swap(values &i64, length usize) i64 {
	if length != 3 { return -2_147_483_649 }
	data := unsafe { values[0] }
	pos_a := unsafe { values[1] }
	pos_b := unsafe { values[2] }
	if data < -2_147_483_648 || data > 2_147_483_647 || pos_a < 0 || pos_a >= 32 || pos_b < 0 || pos_b >= 32 { return -2_147_483_649 }
	mut bits := u32(data)
	mask_a := u32(1) << u32(pos_a)
	mask_b := u32(1) << u32(pos_b)
	bit_a := (bits >> u32(pos_a)) & u32(1)
	bit_b := (bits >> u32(pos_b)) & u32(1)
	if bit_a != bit_b { bits ^= mask_a ^ mask_b }
	if bits <= 0x7fff_ffff { return i64(bits) }
	return i64(bits) - 4_294_967_296
}
