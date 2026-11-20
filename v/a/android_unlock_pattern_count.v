module android_unlock_pattern_count

fn middle_point(first int, second int) int {
	if first == second { return -1 }
	first_x := first % 3
	first_y := first / 3
	second_x := second % 3
	second_y := second / 3
	delta_x := second_x - first_x
	delta_y := second_y - first_y
	if delta_x % 2 != 0 || delta_y % 2 != 0 { return -1 }
	middle := ((first_y + second_y) / 2) * 3 + (first_x + second_x) / 2
	if middle == first || middle == second { return -1 }
	return middle
}

fn count_from(last int, visited int, used int, target int) i64 {
	if used == target { return 1 }
	mut count := i64(0)
	for next in 0 .. 9 {
		bit := 1 << next
		if (visited & bit) != 0 { continue }
		middle := middle_point(last, next)
		if middle >= 0 && (visited & (1 << middle)) == 0 { continue }
		count += count_from(next, visited | bit, used + 1, target)
	}
	return count
}

@[export: 'android_unlock_pattern_count']
pub fn android_unlock_pattern_count(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		target_value := input[0]
		if target_value < 4 || target_value > 9 { return -1 }
		mut count := i64(0)
		for start in 0 .. 9 {
			count += count_from(start, 1 << start, 1, int(target_value))
		}
		return count
	}
}
