module self_number_count_sieve

const max_limit = i64(100000)
const max_parseable_length = 2

fn digit_sum10(value i64) i64 {
	mut remaining := value
	mut sum := i64(0)
	for remaining > 0 {
		sum += remaining % 10
		remaining /= 10
	}
	return sum
}

@[export: 'self_number_count_sieve']
pub fn self_number_count_sieve(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_parseable_length) { return -1 }
		limit := input[0]
		if length != 1 || limit < 1 || limit > max_limit { return -1 }

		mut generated := [1563]u64{}
		for source := i64(1); source <= limit; source++ {
			target := source + digit_sum10(source)
			if target <= limit {
				word := int(target / 64)
				bit := u32(target % 64)
				generated[word] |= u64(1) << bit
			}
		}
		mut count := i64(0)
		for value := i64(1); value <= limit; value++ {
			word := int(value / 64)
			bit := u32(value % 64)
			if generated[word] & (u64(1) << bit) == 0 { count++ }
		}
		return count
	}
}
