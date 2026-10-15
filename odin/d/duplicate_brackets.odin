package duplicate_brackets

import "core:c"

@(export)
duplicate_brackets :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if length < 1 do return -1
	count := packed[0]
	if count < 0 || count > 256 || length != c.size_t(count) + 1 do return -1
	depth: i64 = 0
	for index: i64 = 0; index < count; index += 1 {
		ch := packed[index + 1]
		if ch < 32 || ch > 126 do return -1
		if ch == 40 do depth += 1
		if ch == 41 {
			depth -= 1
			if depth < 0 do return -1
		}
	}
	if depth != 0 do return -1
	stack: [256]i64
	top: usize = 0
	for index: i64 = 0; index < count; index += 1 {
		ch := packed[index + 1]
		if ch == 41 {
			if top == 0 || stack[top - 1] == 40 do return 1
			for top > 0 && stack[top - 1] != 40 { top -= 1 }
			if top > 0 do top -= 1
		} else {
			stack[top] = ch
			top += 1
		}
	}
	return 0
}
