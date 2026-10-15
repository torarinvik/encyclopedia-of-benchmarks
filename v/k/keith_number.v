module keith_number

@[export: 'keith_number']
pub fn keith_number(number i64) i64 {
	if number < 10 || number > 999999 { return -1 }
	mut reversed := [6]i64{}
	mut digits := [6]i64{}
	mut value := number
	mut digit_count := i64(0)
	for value > 0 {
		reversed[digit_count] = value % 10
		digit_count++
		value /= 10
	}
	for i := i64(0); i < digit_count; i++ {
		digits[i] = reversed[digit_count - 1 - i]
	}

	mut oldest := i64(0)
	for {
		mut next := i64(0)
		for i := i64(0); i < digit_count; i++ {
			next += digits[(oldest + i) % digit_count]
		}
		if next >= number { return if next == number { 1 } else { 0 } }
		digits[oldest] = next
		oldest = (oldest + 1) % digit_count
	}
	return -1
}
