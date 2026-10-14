package bingo_sort

import "core:c"

MAX_VALUES :: 1024

@(export)
bingo_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length > c.size_t(MAX_VALUES) || length < 2 { return }
	n := int(length)
	bingo := values[0]
	for index := 1; index < n; index += 1 {
		if values[index] < bingo { bingo = values[index] }
	}
	next_position := 0
	for next_position < n {
		has_next := false
		next_bingo := i64(0)
		for index := next_position; index < n; index += 1 {
			if values[index] == bingo {
				temporary := values[index]
				values[index] = values[next_position]
				values[next_position] = temporary
				next_position += 1
			} else if !has_next || values[index] < next_bingo {
				next_bingo = values[index]
				has_next = true
			}
		}
		if next_position == n { break }
		bingo = next_bingo
	}
}
