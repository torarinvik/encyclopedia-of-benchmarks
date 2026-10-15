module is_srilankan_phone_number

@[export: 'is_srilankan_phone_number']
pub fn is_srilankan_phone_number(phone &i64, length usize) i64 {
	if length == 0 || length > 15 { return -1 }
	if unsafe { phone == nil } { return -1 }
	for i in 0 .. length {
		value := unsafe { phone[i] }
		if value < 0 || value > 127 { return -1 }
	}

	prefix_length := if unsafe { phone[0] == 48 } {
		if length >= 4 && unsafe { phone[1] == 48 && phone[2] == 57 && phone[3] == 52 } {
			usize(4)
		} else {
			usize(1)
		}
	} else if length >= 2 && unsafe { phone[0] == 57 && phone[1] == 52 } {
		usize(2)
	} else if length >= 3 && unsafe { phone[0] == 43 && phone[1] == 57 && phone[2] == 52 } {
		usize(3)
	} else {
		return 0
	}

	mut cursor := prefix_length
	if cursor + 2 > length || unsafe { phone[cursor] != 55 } { return 0 }
	cursor++
	provider := unsafe { phone[cursor] }
	cursor++
	if provider != 48 && provider != 49 && provider != 50 && provider != 52 &&
		provider != 53 && provider != 54 && provider != 55 && provider != 56 { return 0 }

	mut end := length
	if unsafe { phone[end - 1] == 10 } { end-- }
	remaining := end - cursor
	if remaining == 8 && unsafe { phone[cursor] == 45 || phone[cursor] == 32 } {
		cursor++
	} else if remaining != 7 {
		return 0
	}
	for i in 0 .. 7 {
		digit := unsafe { phone[cursor + i] }
		if digit < 48 || digit > 57 { return 0 }
	}
	return 1
}
