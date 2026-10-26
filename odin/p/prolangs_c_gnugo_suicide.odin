package prolangs_c_gnugo_suicide

import "core:c"

// GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
// Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
// Upstream suicide/eval/countlib/count are under GNU GPL version 1; derivative under GPLv1.
group_liberties :: proc(board: [361]u8, start: int, color: u8) -> int {
	seen: [361]bool
	lib_seen: [361]bool
	stack: [361]int
	top := 1; total := 0; stack[0] = start; seen[start] = true
	for top > 0 {
		top -= 1; at := stack[top]; r, c := at/19, at%19
		nb: [4]int; n := 0
		if r > 0 { nb[n] = at-19; n += 1 }; if r < 18 { nb[n] = at+19; n += 1 }
		if c > 0 { nb[n] = at-1; n += 1 }; if c < 18 { nb[n] = at+1; n += 1 }
		for j in 0..<n { next := nb[j]
			if board[next] == 0 { if !lib_seen[next] { lib_seen[next] = true; total += 1 } }
			else if board[next] == color && !seen[next] { seen[next] = true; stack[top] = next; top += 1 }
		}
	}
	return total
}

@(export)
prolangs_c_gnugo_suicide :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 6 || length > 246 do return -1
	row, col, own, opponent, ko, count := input[0], input[1], input[2], input[3], input[4], input[5]
	if row < 0 || row >= 19 || col < 0 || col >= 19 || (own != 1 && own != 2) || (opponent != 1 && opponent != 2) || own == opponent || ko < -1 || ko >= 361 || count < 0 || count > 120 do return -1
	if i64(length) != 6 + 2*count do return -1
	board: [361]u8
	for k in 0..<int(count) { at, stone := input[6+2*k], input[7+2*k]
		if at < 0 || at >= 361 || (stone != 1 && stone != 2) do return -1
		if board[int(at)] != 0 do return -1
		board[int(at)] = u8(stone)
	}
	target := int(row*19+col); if board[target] != 0 do return -1
	board[target] = u8(opponent)
	if group_liberties(board,target,u8(opponent)) > 0 do return 0
	dead: i64 = 0
	for i in 0..<361 { if board[i] == u8(own) && group_liberties(board,i,u8(own)) == 0 do dead += 1 }
	if dead == 0 || (dead == 1 && ko == i64(target)) do return 1
	return 0
}
