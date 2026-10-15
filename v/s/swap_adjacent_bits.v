module swap_adjacent_bits

@[export: 'swap_adjacent_bits']
pub fn swap_adjacent_bits(input i64) i64 {
	if input < 0 || input > 1_073_741_823 { return -1 }
	return ((input & 0xAAAAAAAA) >> 1) | ((input & 0x55555555) << 1)
}
