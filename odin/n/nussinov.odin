package main

import "core:c"

MAX_N :: 128

@(export)
nussinov :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 1 || values[0] < 1 || values[0] > MAX_N do return -1
	n := int(values[0])
	var bases: [MAX_N]i64
	var table: [MAX_N][MAX_N]i64
	for i := 0; i < n; i += 1 { bases[i] = i64((i + 1) % 4) }

	for i := n-1; i >= 0; i -= 1 {
		for j := i+1; j < n; j += 1 {
			score := table[i][j-1]
			if i+1 < n {
				if table[i+1][j] > score { score = table[i+1][j] }
				inside := table[i+1][j-1]
				if i < j-1 && bases[i]+bases[j] == 3 { inside += 1 }
				if inside > score { score = inside }
			}
			for k := i+1; k < j; k += 1 {
				split := table[i][k] + table[k+1][j]
				if split > score { score = split }
			}
			table[i][j] = score
		}
	}

	checksum: i64 = 0
	for row := 0; row < n; row += 1 {
		for col := row; col < n; col += 1 { checksum += table[row][col] }
	}
	return checksum
}
