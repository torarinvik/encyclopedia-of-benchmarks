@[export: 'fifteen_puzzle_solvability']
pub fn fifteen_puzzle_solvability(input &i64, length usize) i64 {
	if length != 16 { return -1 }
	unsafe {
		if input == nil { return -1 }
		mut blank := i64(-1)
		for i in 0 .. 16 {
			value := input[i]
			if value < 0 || value >= 16 { return -1 }
			for j in 0 .. i {
				if value == input[j] { return -1 }
			}
			if value == 0 { blank = i64(i) }
		}
		if blank < 0 { return -1 }

		mut inversions := i64(0)
		for i in 0 .. 16 {
			if input[i] == 0 { continue }
			for j in (i + 1) .. 16 {
				if input[j] != 0 && input[i] > input[j] { inversions++ }
			}
		}
		blank_row_from_top := blank / 4 + 1
		if (inversions + blank_row_from_top) % 2 == 0 { return 1 }
		return 0
	}
}
