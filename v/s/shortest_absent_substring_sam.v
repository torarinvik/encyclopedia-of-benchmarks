@[export: 'shortest_absent_substring_sam']
pub fn shortest_absent_substring_sam(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 66 { return -1 }
		if input[0] < 2 || input[0] > 4 || input[1] < 0 || input[1] > 64 { return -1 }
		alphabet := int(input[0]); n := int(input[1])
		if length != usize(2+n) { return -1 }
		for i in 0 .. n { if input[2+i] < 0 || input[2+i] >= i64(alphabet) { return -1 } }
		mut edges := [516]int{}; mut links := [129]int{}; mut lens := [129]int{}
		for i in 0 .. 516 { edges[i] = -1 }
		for i in 0 .. 129 { links[i] = -1 }
		mut size := 1; mut last := 0
		for i in 0 .. n {
			symbol := int(input[2+i]); current := size; size++; lens[current] = lens[last]+1; mut p := last
			for p >= 0 && edges[4*p+symbol] < 0 { edges[4*p+symbol] = current; p = links[p] }
			if p < 0 { links[current] = 0 } else {
				q := edges[4*p+symbol]
				if lens[p]+1 == lens[q] { links[current] = q } else {
					clone := size; size++
					for a in 0 .. 4 { edges[4*clone+a] = edges[4*q+a] }
					links[clone] = links[q]; lens[clone] = lens[p]+1
					for p >= 0 && edges[4*p+symbol] == q { edges[4*p+symbol] = clone; p = links[p] }
					links[q] = clone; links[current] = clone
				}
			}
			last = current
		}
		mut counts := [65]int{}; mut order := [129]int{}; mut dp := [129]int{}
		for s in 0 .. size { counts[lens[s]]++ }
		for i in 1 .. n+1 { counts[i] += counts[i-1] }
		for offset in 0 .. size { s := size-1-offset; counts[lens[s]]--; order[counts[lens[s]]] = s }
		for offset in 0 .. size {
			s := order[size-1-offset]; mut best := 100
			for a in 0 .. alphabet {
				child := edges[4*s+a]; mut candidate := 1
				if child >= 0 { candidate += dp[child] }
				if candidate < best { best = candidate }
			}
			dp[s] = best
		}
		mut result := [6]u8{}; mut count := 0; mut state := 0
		for state >= 0 {
			for a in 0 .. alphabet {
				child := edges[4*state+a]; mut eligible := child < 0 && dp[state] == 1
				if child >= 0 { eligible = dp[state] == 1+dp[child] }
				if eligible { result[count] = u8(a); count++; state = child; break }
			}
		}
		if output == nil || capacity < usize(count) { return -2 }
		for i in 0 .. count { output[i] = result[i] }
		return i64(count)
	}
}
