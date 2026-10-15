module reverse_bits

// Reverse the bit order of an unsigned 32-bit word.
@[export: 'reverse_bits']
pub fn reverse_bits(value i64) i64 {
	if value < 0 || value > 4_294_967_295 { return -1 }
	mut remaining := u32(value)
	mut reversed := u32(0)
	for _ in 0 .. 32 {
		reversed = (reversed << 1) | (remaining & 1)
		remaining >>= 1
	}
	return i64(reversed)
}
