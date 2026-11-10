module smallest_divisor

// Find the least positive divisor whose rounded sum fits the threshold.
@[export: 'smallest_divisor']
pub fn smallest_divisor(input &i64, length usize) i64 {
	if length < 2 || length > 257 { return -1 }
	count := u64(length - 1)
	threshold := u64(unsafe { input[0] })
	if threshold < count || threshold > 1_000_000 { return -1 }
	mut maximum := u64(0)
	mut total := u64(0)
	for index in 1 .. length {
		value := u64(unsafe { input[index] })
		if value == 0 || value > 1_000_000 { return -1 }
		if value > maximum { maximum = value }
		total += value
	}
	if threshold == count { return i64(maximum) }

	mut low := (total - 1) / threshold + 1
	upper_bound := (total - count) / (threshold - count + 1) + 1
	mut high := if upper_bound < maximum { upper_bound } else { maximum }
	for low < high {
		middle := low + ((high - low) >> 1)
		mut rounded_sum := count
		if count <= 4 {
			for index in 1 .. length {
				value := u32(unsafe { input[index] })
				rounded_sum += u64((value - 1) / u32(middle))
			}
		} else {
			reciprocal := (u64(1_099_511_627_775) / middle) + 1
			for index in 1 .. length {
				value := u64(unsafe { input[index] })
				rounded_sum += ((value - 1) * reciprocal) >> 40
			}
		}
		if rounded_sum <= threshold { high = middle } else { low = middle + 1 }
	}
	return i64(low)
}
