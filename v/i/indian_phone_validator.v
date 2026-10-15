module indian_phone_validator

fn is_ascii_whitespace(value i64) bool {
	return value == 9 || value == 10 || value == 11 || value == 12 || value == 13 || value == 32
}

fn mobile_tail(phone &i64, ending usize, position usize) bool {
	if position > ending || ending - position != 10 { return false }
	if unsafe { phone[position] < 55 || phone[position] > 57 } { return false }
	for i in 1 .. 10 {
		digit := unsafe { phone[position + i] }
		if digit < 48 || digit > 57 { return false }
	}
	return true
}

@[export: 'indian_phone_validator']
pub fn indian_phone_validator(phone &i64, length usize) i64 {
	if length == 0 || length > 18 { return -1 }
	if unsafe { phone == nil } { return -1 }
	for i in 0 .. length {
		value := unsafe { phone[i] }
		if value < 0 || value > 127 { return -1 }
	}

	mut ending := length
	if unsafe { phone[ending - 1] == 10 } { ending-- }
	mut prefix := usize(0)
	if ending >= 3 && unsafe { phone[0] == 43 && phone[1] == 57 && phone[2] == 49 } {
		prefix = 3
		if prefix < ending && unsafe { phone[prefix] == 45 || is_ascii_whitespace(phone[prefix]) } { prefix++ }
	}

	for zero in 0 .. 2 {
		mut after_zero := prefix
		if zero == 1 {
			if after_zero >= ending || unsafe { phone[after_zero] != 48 } { continue }
			after_zero++
		}
		for country in 0 .. 2 {
			mut position := after_zero
			if country == 1 {
				if position + 2 > ending || unsafe { phone[position] != 57 || phone[position + 1] != 49 } { continue }
				position += 2
			}
			if mobile_tail(phone, ending, position) { return 1 }
		}
	}
	return 0
}
