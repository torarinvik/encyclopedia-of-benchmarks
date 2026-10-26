module prolangs_c_gnugo_liberty_count

// GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
// Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
// Upstream countlib/count are under GNU GPL version 1; this derivative is licensed under GNU GPL version 1.
@[export: 'prolangs_c_gnugo_liberty_count']
pub fn prolangs_c_gnugo_liberty_count(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 726 { return -1 }
		row, col, color, count := input[0], input[1], input[2], input[3]
		if row < 0 || row >= 19 || col < 0 || col >= 19 || (color != 1 && color != 2) || count < 0 || count > 361 || length != usize(4+2*count) { return -1 }
		mut board := [361]u8{}
		mut seen := [361]bool{}
		mut liberties := [361]bool{}
		for k := 0; k < int(count); k++ {
			at, stone := input[4+2*k], input[5+2*k]
			if at < 0 || at >= 361 || (stone != 1 && stone != 2) || board[int(at)] != 0 { return -1 }
			board[int(at)] = u8(stone)
		}
		start := int(row*19+col)
		if board[start] != u8(color) { return -1 }
		mut stack := [361]int{}
		mut top := 1
		mut total := i64(0)
		stack[0] = start; seen[start] = true
		for top > 0 {
			top--
			at := stack[top]; r, c := at/19, at%19
			mut neighbors := [4]int{}
			mut n := 0
			if r > 0 { neighbors[n] = at-19; n++ }
			if r < 18 { neighbors[n] = at+19; n++ }
			if c > 0 { neighbors[n] = at-1; n++ }
			if c < 18 { neighbors[n] = at+1; n++ }
			for j := 0; j < n; j++ {
				next := neighbors[j]
				if board[next] == 0 {
					if !liberties[next] { liberties[next] = true; total++ }
				} else if board[next] == u8(color) && !seen[next] {
					seen[next] = true; stack[top] = next; top++
				}
			}
		}
		return total
	}
}
