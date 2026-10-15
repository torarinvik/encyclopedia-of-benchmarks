module longest_valid_parentheses_stack

const max_length = 4096

// Track unmatched opening positions and reset after an unmatched close.
@[export: 'longest_valid_parentheses_stack']
pub fn longest_valid_parentheses_stack(input &i64, length usize) i64 {
	if length > max_length || (length != 0 && input == nil) { return -1 }
	for index in 0 .. length {
		value := unsafe { input[index] }
		if value != 40 && value != 41 { return -1 }
	}

	mut unmatched := [max_length + 1]int{}
	mut top := 0
	unmatched[0] = -1
	mut best := 0
	for index in 0 .. length {
		if unsafe { input[index] } == 40 {
			top++
			unmatched[top] = int(index)
		} else if top == 0 {
			unmatched[0] = int(index)
		} else {
			top--
			current := int(index) - unmatched[top]
			if current > best { best = current }
		}
	}
	return i64(best)
}
