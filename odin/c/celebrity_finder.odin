package celebrity_finder

import "core:c"

@(export)
celebrity_finder :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || input[0] < 1 || input[0] > 64 do return -2
	n := int(input[0])
	if int(length) != 1 + n * n do return -2
	for i := 1; i < int(length); i += 1 { if input[i] != 0 && input[i] != 1 do return -2 }
	stack: [64]int
	top := 0
	for i := 0; i < n; i += 1 { stack[top] = i; top += 1 }
	for top > 1 {
		top -= 1; person1 := stack[top]
		top -= 1; person2 := stack[top]
		if input[1 + person1 * n + person2] == 1 { stack[top] = person2 } else { stack[top] = person1 }
		top += 1
	}
	candidate := stack[0]
	for i := 0; i < n; i += 1 {
		if i != candidate && (input[1 + candidate * n + i] == 1 || input[1 + i * n + candidate] == 0) do return -1
	}
	return i64(candidate)
}
