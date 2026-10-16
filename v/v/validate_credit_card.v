module validate_credit_card

const max_text_length = 64

@[export: 'validate_credit_card']
pub fn validate_credit_card(input &i64, length usize) i64 {
	if length < 1 || length > max_text_length + 1 { return -1 }
	n := unsafe { input[0] }
	if n < 0 || n > max_text_length || length != usize(n + 1) { return -1 }
	for i in 0 .. int(n) {
		code := unsafe { input[i + 1] }
		if code < 0 || code > 127 { return -1 }
	}
	if n < 13 || n > 16 { return 0 }
	for i in 0 .. int(n) {
		code := unsafe { input[i + 1] }
		if code < 48 || code > 57 { return 0 }
	}
	first := unsafe { input[1] - 48 }
	second := unsafe { input[2] - 48 }
	if !(first == 4 || first == 5 || first == 6 ||
		(first == 3 && (second == 4 || second == 5 || second == 7))) { return 0 }
	mut total := i64(0)
	for i in 0 .. int(n) {
		mut digit := unsafe { input[i + 1] - 48 }
		if i % 2 == 0 {
			digit *= 2
			if digit > 9 { digit -= 9 }
		}
		total += digit
	}
	if total % 10 == 0 { return 1 }
	return 0
}
