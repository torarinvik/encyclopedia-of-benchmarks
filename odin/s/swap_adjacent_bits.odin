package swap_adjacent_bits

@(export)
swap_adjacent_bits :: proc "contextless" (input: i64) -> i64 {
	if input < 0 || input > 1_073_741_823 do return -1
	return ((input & 0xAAAAAAAA) >> 1) | ((input & 0x55555555) << 1)
}
