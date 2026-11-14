@[export: 'longest_common_substring_sam']
pub fn longest_common_substring_sam(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 515 || input[0] < 0 || input[0] > 256 { return -1 }
		n := int(input[0])
		if length < usize(n+2) || input[n+1] < 0 || input[n+1] > 256 { return -1 }
		m := int(input[n+1])
		if length != usize(n+m+2) { return -1 }
		for i in 0 .. n { if input[1+i] < 32 || input[1+i] > 126 { return -1 } }
		for i in 0 .. m { if input[n+2+i] < 32 || input[n+2+i] > 126 { return -1 } }
		mut edges := [48735]int{}; mut links := [513]int{}; mut lens := [513]int{}
		for i in 0 .. 48735 { edges[i] = -1 }
		for i in 0 .. 513 { links[i] = -1 }
		mut size := 1; mut last := 0
		for i in 0 .. n {
			symbol := int(input[1+i])-32; current := size; size++; lens[current] = lens[last]+1; mut p := last
			for p >= 0 && edges[95*p+symbol] < 0 { edges[95*p+symbol] = current; p = links[p] }
			if p < 0 { links[current] = 0 } else {
				q := edges[95*p+symbol]
				if lens[p]+1 == lens[q] { links[current] = q } else {
					clone := size; size++
					for a in 0 .. 95 { edges[95*clone+a] = edges[95*q+a] }
					links[clone] = links[q]; lens[clone] = lens[p]+1
					for p >= 0 && edges[95*p+symbol] == q { edges[95*p+symbol] = clone; p = links[p] }
					links[q] = clone; links[current] = clone
				}
			}
			last = current
		}
		mut state := 0; mut matched := 0; mut best := 0
		for i in 0 .. m {
			symbol := int(input[n+2+i])-32
			for state != 0 && edges[95*state+symbol] < 0 { state = links[state]; matched = lens[state] }
			next := edges[95*state+symbol]
			if next < 0 { state = 0; matched = 0 } else { state = next; matched++; if matched > best { best = matched } }
		}
		return i64(best)
	}
}
