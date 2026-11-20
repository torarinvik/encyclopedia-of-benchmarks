package fractional_cascading_subset_chain

import "core:c"

MAX_M :: 8
MAX_Q :: 8
MAX_N :: 16
MAX_LENGTH :: 147
NO_SUCCESSOR :: i64(34)

@(export)
fractional_cascading_subset_chain :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_LENGTH do return -1
	if input[0] < 2 || input[0] > MAX_M || input[1] < 1 || input[1] > MAX_Q do return -1
	m, q := int(input[0]), int(input[1])
	var catalogs: [MAX_M][MAX_N]i64
	var sizes: [MAX_M]int
	var queries: [MAX_Q]i64
	cursor := 2
	for i in 0 ..< m {
		if cursor >= int(length) || input[cursor] < 1 || input[cursor] > MAX_N do return -1
		n := int(input[cursor]); cursor += 1
		if cursor + n > int(length) do return -1
		sizes[i] = n
		for j in 0 ..< n {
			key := input[cursor]; cursor += 1
			if key < -16 || key > 16 || (j > 0 && catalogs[i][j-1] >= key) do return -1
			catalogs[i][j] = key
		}
		if i > 0 {
			parent_pos, child_pos := 0, 0
			for parent_pos < sizes[i-1] && child_pos < n {
				if catalogs[i-1][parent_pos] < catalogs[i][child_pos] {
					parent_pos += 1
				} else if catalogs[i-1][parent_pos] == catalogs[i][child_pos] {
					parent_pos += 1; child_pos += 1
				} else { return -1 }
			}
			if child_pos != n do return -1
		}
	}
	if cursor + q != int(length) do return -1
	for i in 0 ..< q { queries[i] = input[cursor+i]; if queries[i] < -17 || queries[i] > 17 do return -1 }
	var bridge: [MAX_M-1][MAX_N+1]int
	for i in 0 ..< m-1 {
		child := 0
		for slot in 0 ..< sizes[i] {
			for child < sizes[i+1] && catalogs[i+1][child] < catalogs[i][slot] { child += 1 }
			bridge[i][slot] = child
		}
		bridge[i][sizes[i]] = sizes[i+1]
	}
	checksum: i64 = 0
	for qi in 0 ..< q {
		low, high := 0, sizes[0]
		for low < high {
			mid := (low+high)/2
			if catalogs[0][mid] < queries[qi] { low = mid+1 } else { high = mid }
		}
		slot := low
		for ci in 0 ..< m {
			code := NO_SUCCESSOR
			if slot < sizes[ci] { code = catalogs[ci][slot]+17 }
			checksum += i64(qi+1)*i64(ci+1)*code
			if ci+1 < m { slot = bridge[ci][slot] }
		}
	}
	return checksum
}
