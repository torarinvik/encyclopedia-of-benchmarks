module count_number_of_one_bits

@[export: 'count_number_of_one_bits']
pub fn count_number_of_one_bits(number i64, method i64) i64 {
	if number < 0 || number > 4_294_967_295 || method < 0 || method > 2 { return -1 }
	mut remaining := u32(number)
	mut count := i64(0)
	if method == 0 {
		for remaining != 0 {
			remaining &= remaining - 1
			count++
		}
		return count
	}
	if method == 1 {
		for remaining != 0 {
			if remaining % 2 == 1 { count++ }
			remaining >>= 1
		}
		return count
	}
	mut lookup := [256]i64{}
	for index in 1 .. 256 { lookup[index] = lookup[index >> 1] + i64(index & 1) }
	return lookup[usize(remaining & 0xff)] + lookup[usize((remaining >> 8) & 0xff)]
		+ lookup[usize((remaining >> 16) & 0xff)] + lookup[usize((remaining >> 24) & 0xff)]
}
