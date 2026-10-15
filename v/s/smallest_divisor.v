module smallest_divisor

// Find the least positive divisor whose rounded sum fits the threshold.
@[export: 'smallest_divisor']
pub fn smallest_divisor(input &i64, length usize) i64 {
	if length < 2 || length > 257 { return -1 }
	threshold := unsafe { input[0] }
	if threshold < 1 || threshold > 1_000_000 { return -1 }
	mut maximum := i64(0)
	for index in 1 .. length {
		value := unsafe { input[index] }
		if value < 1 || value > 1_000_000 { return -1 }
		if value > maximum { maximum = value }
	}
	count := i64(length - 1)
	if threshold < count { return -1 }
	mut low := i64(1)
	mut high := maximum
	for low < high {
		middle := low + (high - low) / 2
		mut sum := i64(0)
		for index in 1 .. length {
			value := unsafe { input[index] }
			sum += (value + middle - 1) / middle
		}
		if sum <= threshold { high = middle }
		else { low = middle + 1 }
	}
	return low
}
