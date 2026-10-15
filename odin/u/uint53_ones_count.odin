package uint53_ones_count

MAX_UINT53 :: i64(9_007_199_254_740_991)

count_byte_ones :: proc(byte: i64) -> i64 {
	current := byte
	ones: i64 = 0
	for current > 0 {
		bit := current % 2
		ones += bit
		current = (current - bit) / 2
	}
	return ones
}

// Count set bits in the bounded unsigned 53-bit domain, byte by byte.
@(export)
uint53_ones_count :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > MAX_UINT53 do return -1

	current := n
	ones: i64 = 0
	for current != 0 {
		byte := current % 256
		ones += count_byte_ones(byte)
		current = (current - byte) / 256
	}
	return ones
}
