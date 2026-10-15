package string_is_valid_number

import "core:c"

@(export)
string_is_valid_number :: proc "c" (bytes: [^]i64, length: c.size_t) -> i64 {
	if length > 256 || (length != 0 && bytes == nil) do return -1
	for i := c.size_t(0); i < length; i += 1 {
		if bytes[i] < 0 || bytes[i] > 127 do return -1
	}

	state := i64(0)
	for i := c.size_t(0); i < length; i += 1 {
		ch := bytes[i]
		if ch >= 48 && ch <= 57 {
			if state == 0 || state == 1 do state = 2
			else if state == 3 do state = 4
			else if state == 5 || state == 6 do state = 7
			else if state != 2 && state != 4 && state != 7 do return 0
		} else if ch == 43 || ch == 45 {
			if state == 0 do state = 1
			else if state == 5 do state = 6
			else do return 0
		} else if ch == 46 {
			if state == 0 || state == 1 do state = 3
			else if state == 2 do state = 4
			else do return 0
		} else if ch == 101 || ch == 69 {
			if state == 2 || state == 4 do state = 5
			else do return 0
		} else {
			return 0
		}
	}
	return i64(state == 2 || state == 4 || state == 7)
}
