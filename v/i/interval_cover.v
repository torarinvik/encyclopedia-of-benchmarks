// Greedy minimum subfamily covering a half-open target interval.
@[export: 'interval_cover']
pub fn interval_cover(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 36 { return -2 }
		target_left := input[0]
		target_right := input[1]
		count_value := input[2]
		if target_left < 0 || target_left > target_right || target_right > 32 || count_value < 0 || count_value > 16 { return -2 }
		count := int(count_value)
		if int(length) != 3 + 2 * count { return -2 }
		for i in 0 .. count {
			left := input[3 + 2 * i]
			right := input[4 + 2 * i]
			if left < 0 || left >= right || right > 32 { return -2 }
		}
		if target_left == target_right { return 0 }

		mut frontier := target_left
		mut selected := i64(0)
		for frontier < target_right {
			mut farthest := frontier
			for i in 0 .. count {
				left := input[3 + 2 * i]
				right := input[4 + 2 * i]
				if left <= frontier && right > farthest { farthest = right }
			}
			if farthest == frontier { return -1 }
			frontier = farthest
			selected += 1
		}
		return selected
	}
}
