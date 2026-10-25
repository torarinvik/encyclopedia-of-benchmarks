package rodinia_bplus_tree

import "core:c"

// Root separator routes point lookup into one of two sorted B+ tree leaves.
@(export)
rodinia_bplus_tree :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 7 || length > 31 do return -1
	if input[0] < 1 || input[0] > 3 || input[1] < 1 || input[1] > 3 || input[2] < 1 || input[2] > 16 do return -1
	left_n := int(input[0]); right_n := int(input[1]); query_n := int(input[2])
	if length != c.size_t(3 + 2*(left_n+right_n) + query_n) do return -1
	keys: [2][3]i64
	vals: [2][3]i64
	counts := [2]int{left_n, right_n}
	cursor := 3
	for leaf in 0 ..< 2 {
		for slot in 0 ..< counts[leaf] {
			key := input[cursor]; value := input[cursor+1]; cursor += 2
			if key < -1_000_000 || key > 1_000_000 || value < 0 || value > 1_000_000 do return -1
			if slot > 0 && key <= keys[leaf][slot-1] do return -1
			keys[leaf][slot] = key; vals[leaf][slot] = value
		}
	}
	if keys[0][left_n-1] >= keys[1][0] do return -1
	answer: i64 = 0
	for qi in 0 ..< query_n {
		query := input[cursor]; cursor += 1
		if query < -1_000_000 || query > 1_000_000 do return -1
		leaf := 0
		if query >= keys[1][0] do leaf = 1
		for slot in 0 ..< counts[leaf] {
			if keys[leaf][slot] == query { answer += i64(qi+1)*(vals[leaf][slot]+1); break }
		}
	}
	return answer
}
