package longest_valid_parentheses_stack

import "core:c"

MAX_LENGTH :: 4096

// Track unmatched opening positions to find the longest valid parentheses substring.
@(export)
longest_valid_parentheses_stack :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && input == nil) do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if input[index] != 40 && input[index] != 41 do return -1
	}

	unmatched: [MAX_LENGTH + 1]int
	top := 0
	unmatched[top] = -1
	best := 0
	for index := 0; index < int(length); index += 1 {
		if input[index] == 40 {
			top += 1
			unmatched[top] = index
		} else if top == 0 {
			unmatched[0] = index
		} else {
			top -= 1
			current := index - unmatched[top]
			if current > best do best = current
		}
	}
	return i64(best)
}
