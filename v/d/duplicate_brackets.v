module duplicate_brackets

@[export: 'duplicate_brackets']
pub fn duplicate_brackets(packed &i64, length usize) i64 {
	if length < 1 { return -1 }
	count := unsafe { packed[0] }
	if count < 0 || count > 256 || length != usize(count) + 1 { return -1 }
	mut depth := i64(0)
	for index in 0 .. int(count) {
		ch := unsafe { packed[index + 1] }
		if ch < 32 || ch > 126 { return -1 }
		if ch == 40 { depth++ }
		if ch == 41 {
			depth--
			if depth < 0 { return -1 }
		}
	}
	if depth != 0 { return -1 }
	mut stack := [256]i64{init: 0}
	mut top := 0
	for index in 0 .. int(count) {
		ch := unsafe { packed[index + 1] }
		if ch == 41 {
			if top == 0 || stack[top - 1] == 40 { return 1 }
			for top > 0 && stack[top - 1] != 40 { top-- }
			if top > 0 { top-- }
		} else {
			stack[top] = ch
			top++
		}
	}
	return 0
}
