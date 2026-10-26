package prolangs_c_gnugo_liberty_count

import "core:c"

// GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
// Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
// Upstream countlib/count are under GNU GPL version 1; this derivative is licensed under GNU GPL version 1.
@(export)
prolangs_c_gnugo_liberty_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 726 do return -1
	row, col, color, count := input[0], input[1], input[2], input[3]
	if row < 0 || row >= 19 || col < 0 || col >= 19 || (color != 1 && color != 2) || count < 0 || count > 361 do return -1
	if i64(length) != 4 + 2*count do return -1
	board: [361]u8
	seen: [361]bool
	liberties: [361]bool
	for k in 0..<int(count) {
		at, stone := input[4+2*k], input[5+2*k]
		if at < 0 || at >= 361 || (stone != 1 && stone != 2) do return -1
		index := int(at)
		if board[index] != 0 do return -1
		board[index] = u8(stone)
	}
	start := int(row*19 + col)
	if board[start] != u8(color) do return -1
	stack: [361]int
	top := 1
	total: i64 = 0
	stack[0] = start; seen[start] = true
	for top > 0 {
		top -= 1
		at := stack[top]; r, c := at/19, at%19
		neighbors: [4]int
		n := 0
		if r > 0 { neighbors[n] = at-19; n += 1 }
		if r < 18 { neighbors[n] = at+19; n += 1 }
		if c > 0 { neighbors[n] = at-1; n += 1 }
		if c < 18 { neighbors[n] = at+1; n += 1 }
		for j in 0..<n {
			next := neighbors[j]
			if board[next] == 0 {
				if !liberties[next] { liberties[next] = true; total += 1 }
			} else if board[next] == u8(color) && !seen[next] {
				seen[next] = true; stack[top] = next; top += 1
			}
		}
	}
	return total
}
