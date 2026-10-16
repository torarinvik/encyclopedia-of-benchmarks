module count_homogenous

// Count contiguous runs of equal ASCII bytes.
@[export: 'count_homogenous']
pub fn count_homogenous(input &i64, length usize) i64 {
	if length < 1 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 4096 { return -1 }
		count := int(input[0])
		if int(length) != count + 1 { return -1 }
		for i in 0 .. count {
			if input[1 + i] < 0 || input[1 + i] > 127 { return -1 }
		}
		if count == 0 { return 0 }
		mut runs := 1
		for i in 2 .. count + 1 {
			if input[i] != input[i - 1] { runs++ }
		}
		return i64(runs)
	}
}
