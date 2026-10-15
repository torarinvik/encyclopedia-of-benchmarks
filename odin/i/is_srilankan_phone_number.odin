package is_srilankan_phone_number

import "core:c"

@(export)
is_srilankan_phone_number :: proc "c" (phone: [^]i64, length: c.size_t) -> i64 {
	if phone == nil || length == 0 || length > 15 do return -1
	for i := c.size_t(0); i < length; i += 1 {
		if phone[i] < 0 || phone[i] > 127 do return -1
	}

	prefix_length: c.size_t
	if phone[0] == 48 {
		if length >= 4 && phone[1] == 48 && phone[2] == 57 && phone[3] == 52 {
			prefix_length = 4
		} else {
			prefix_length = 1
		}
	} else if length >= 2 && phone[0] == 57 && phone[1] == 52 {
		prefix_length = 2
	} else if length >= 3 && phone[0] == 43 && phone[1] == 57 && phone[2] == 52 {
		prefix_length = 3
	} else {
		return 0
	}

	cursor := prefix_length
	if cursor + 2 > length || phone[cursor] != 55 do return 0
	cursor += 1
	provider := phone[cursor]
	cursor += 1
	if provider != 48 && provider != 49 && provider != 50 && provider != 52 && provider != 53 && provider != 54 && provider != 55 && provider != 56 { return 0 }

	end := length
	if phone[end - 1] == 10 do end -= 1
	remaining := end - cursor
	if remaining == 8 && (phone[cursor] == 45 || phone[cursor] == 32) {
		cursor += 1
	} else if remaining != 7 {
		return 0
	}
	for i := c.size_t(0); i < 7; i += 1 {
		digit := phone[cursor + i]
		if digit < 48 || digit > 57 do return 0
	}
	return 1
}
