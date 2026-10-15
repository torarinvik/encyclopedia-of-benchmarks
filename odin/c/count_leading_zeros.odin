package count_leading_zeros

@(export)
count_leading_zeros :: proc "c" (value: i64) -> i64 {
	if value < -2147483648 || value > 2147483647 do return -1
	if value == 0 do return 32
	mask := i64(1) << 31
	count := i64(0)
	for (mask & value) == 0 {
		count += 1
		mask >>= 1
	}
	return count
}
