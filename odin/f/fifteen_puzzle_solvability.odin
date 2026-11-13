package fifteen_puzzle_solvability

import "core:c"

@(export)
fifteen_puzzle_solvability :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 16 do return -1

	blank: i64 = -1
	for i in 0..<16 {
		value := input[i]
		if value < 0 || value >= 16 do return -1
		for j in 0..<i {
			if value == input[j] do return -1
		}
		if value == 0 do blank = i64(i)
	}
	if blank < 0 do return -1

	inversions: i64 = 0
	for i in 0..<16 {
		if input[i] == 0 do continue
		for j in (i + 1)..<16 {
			if input[j] != 0 && input[i] > input[j] do inversions += 1
		}
	}
	blank_row_from_top := blank / 4 + 1
	if (inversions + blank_row_from_top) % 2 == 0 do return 1
	return 0
}
