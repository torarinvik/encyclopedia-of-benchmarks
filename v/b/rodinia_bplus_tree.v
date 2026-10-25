module rodinia_bplus_tree

// Root separator routes point lookup into one of two sorted B+ tree leaves.
@[export: 'rodinia_bplus_tree']
pub fn rodinia_bplus_tree(input &i64, length usize) i64 {
	if length < 7 || length > 31 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 3 || input[1] < 1 || input[1] > 3 || input[2] < 1 || input[2] > 16 { return -1 }
		left_n := int(input[0]); right_n := int(input[1]); query_n := int(input[2])
		if length != usize(3 + 2*(left_n+right_n) + query_n) { return -1 }
		mut keys := [2][3]i64{}
		mut vals := [2][3]i64{}
		counts := [left_n, right_n]
		mut cursor := 3
		for leaf := 0; leaf < 2; leaf++ {
			for slot := 0; slot < counts[leaf]; slot++ {
				key := input[cursor]; value := input[cursor+1]; cursor += 2
				if key < -1000000 || key > 1000000 || value < 0 || value > 1000000 { return -1 }
				if slot > 0 && key <= keys[leaf][slot-1] { return -1 }
				keys[leaf][slot] = key; vals[leaf][slot] = value
			}
		}
		if keys[0][left_n-1] >= keys[1][0] { return -1 }
		mut answer := i64(0)
		for qi := 0; qi < query_n; qi++ {
			query := input[cursor]; cursor++
			if query < -1000000 || query > 1000000 { return -1 }
			leaf := if query < keys[1][0] { 0 } else { 1 }
			for slot := 0; slot < counts[leaf]; slot++ {
				if keys[leaf][slot] == query { answer += i64(qi+1)*(vals[leaf][slot]+1); break }
			}
		}
		return answer
	}
}
