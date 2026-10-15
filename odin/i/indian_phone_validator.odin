package indian_phone_validator

import "core:c"

is_ascii_whitespace :: proc "contextless" (value: i64) -> bool {
	return value == 9 || value == 10 || value == 11 || value == 12 || value == 13 || value == 32
}

mobile_tail :: proc "contextless" (phone: [^]i64, ending, position: c.size_t) -> bool {
	if position > ending || ending - position != 10 do return false
	if phone[position] < 55 || phone[position] > 57 do return false
	for i := c.size_t(1); i < 10; i += 1 {
		if phone[position + i] < 48 || phone[position + i] > 57 do return false
	}
	return true
}

@(export)
indian_phone_validator :: proc "c" (phone: [^]i64, length: c.size_t) -> i64 {
	if phone == nil || length == 0 || length > 18 do return -1
	for i := c.size_t(0); i < length; i += 1 {
		if phone[i] < 0 || phone[i] > 127 do return -1
	}

	ending := length
	if phone[ending - 1] == 10 do ending -= 1
	prefix: c.size_t = 0
	if ending >= 3 && phone[0] == 43 && phone[1] == 57 && phone[2] == 49 {
		prefix = 3
		if prefix < ending && (phone[prefix] == 45 || is_ascii_whitespace(phone[prefix])) do prefix += 1
	}

	for zero := 0; zero <= 1; zero += 1 {
		after_zero := prefix
		if zero == 1 {
			if after_zero >= ending || phone[after_zero] != 48 do continue
			after_zero += 1
		}
		for country := 0; country <= 1; country += 1 {
			position := after_zero
			if country == 1 {
				if position + 2 > ending || phone[position] != 57 || phone[position + 1] != 49 do continue
				position += 2
			}
			if mobile_tail(phone, ending, position) do return 1
		}
	}
	return 0
}
