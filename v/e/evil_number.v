module evil_number

// Return 1 when a nonnegative integer has an even popcount.
@[export: 'evil_number']
pub fn evil_number(value i64) i64 {
	if value < 0 {
		return -1
	}
	mut remaining := value
	mut count := i64(0)
	for remaining > 0 {
		count += remaining & 1
		remaining >>= 1
	}
	if count % 2 == 0 {
		return 1
	}
	return 0
}
