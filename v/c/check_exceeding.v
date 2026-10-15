module check_exceeding

const max_length = 4096

// Check nondecreasing letter gaps after ASCII normalization and filtering.
@[export: 'check_exceeding']
pub fn check_exceeding(values &i64, length usize) i64 {
	if length > max_length { return -2 }
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 32 || value > 126 { return -2 }
	}

	mut previous_letter := i64(-1)
	mut previous_gap := i64(-1)
	for index in 0 .. int(length) {
		mut letter := unsafe { values[index] }
		if letter >= 97 && letter <= 122 { letter -= 32 }
		if letter < 65 || letter > 90 { continue }
		if previous_letter >= 0 && letter != previous_letter {
			gap := if letter > previous_letter { letter - previous_letter } else { previous_letter - letter }
			if previous_gap >= 0 && gap < previous_gap { return 0 }
			previous_gap = gap
		}
		previous_letter = letter
	}
	return 1
}
