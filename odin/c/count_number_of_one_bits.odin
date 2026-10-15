package count_number_of_one_bits

@(export)
count_number_of_one_bits :: proc "contextless" (number, method: i64) -> i64 {
	if number < 0 || number > 4_294_967_295 || method < 0 || method > 2 do return -1
	remaining := u32(number)
	count: i64 = 0
	if method == 0 {
		for remaining != 0 {
			remaining &= remaining - 1
			count += 1
		}
		return count
	}
	if method == 1 {
		for remaining != 0 {
			if remaining % 2 == 1 do count += 1
			remaining >>= 1
		}
		return count
	}
	lookup: [256]i64
	lookup[0] = 0
	for index := 1; index < 256; index += 1 { lookup[index] = lookup[index >> 1] + i64(index & 1) }
	return lookup[remaining & 0xff] + lookup[(remaining >> 8) & 0xff]
		+ lookup[(remaining >> 16) & 0xff] + lookup[(remaining >> 24) & 0xff]
}
