module twos_complement_of_binary

const max_binary_digit_numeral = i64(1111111111111111)

@[export: 'twos_complement_of_binary']
pub fn twos_complement_of_binary(value i64) i64 {
	if value < 0 || value > max_binary_digit_numeral { return -1 }
	if value == 0 { return 0 }

	mut remaining := value
	for remaining > 0 {
		digit := remaining % 10
		if digit != 0 && digit != 1 { return -1 }
		remaining /= 10
	}

	remaining = value
	mut reversed := i64(0)
	mut width := i64(0)
	for remaining > 0 && remaining % 10 == 0 {
		reversed = reversed * 10 + remaining % 10
		remaining /= 10
		width++
	}
	if remaining > 0 {
		reversed = reversed * 10 + remaining % 10
		remaining /= 10
		width++
	}
	for remaining > 0 {
		digit := remaining % 10
		reversed = reversed * 10 + if digit == 1 { i64(0) } else { i64(1) }
		remaining /= 10
		width++
	}

	mut result := i64(0)
	for width > 0 {
		result = result * 10 + reversed % 10
		reversed /= 10
		width--
	}
	return result
}
