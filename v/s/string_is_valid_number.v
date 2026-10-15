module string_is_valid_number

@[export: 'string_is_valid_number']
pub fn string_is_valid_number(bytes &i64, length usize) i64 {
	if length > 256 { return -1 }
	if length > 0 && unsafe { bytes == nil } { return -1 }
	for i in 0 .. length {
		ch := unsafe { bytes[i] }
		if ch < 0 || ch > 127 { return -1 }
	}

	mut state := i64(0)
	for i in 0 .. length {
		ch := unsafe { bytes[i] }
		if ch >= 48 && ch <= 57 {
			if state == 0 || state == 1 { state = 2 }
			else if state == 3 { state = 4 }
			else if state == 5 || state == 6 { state = 7 }
			else if state != 2 && state != 4 && state != 7 { return 0 }
		} else if ch == 43 || ch == 45 {
			if state == 0 { state = 1 }
			else if state == 5 { state = 6 }
			else { return 0 }
		} else if ch == 46 {
			if state == 0 || state == 1 { state = 3 }
			else if state == 2 { state = 4 }
			else { return 0 }
		} else if ch == 101 || ch == 69 {
			if state == 2 || state == 4 { state = 5 }
			else { return 0 }
		} else {
			return 0
		}
	}
	return if state == 2 || state == 4 || state == 7 { 1 } else { 0 }
}
