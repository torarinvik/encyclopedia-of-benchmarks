@[export: 'paint_house_iii']
pub fn paint_house_iii(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 44 { return -1 }
		m_value := input[0]
		n_value := input[1]
		target_value := input[2]
		if m_value < 1 || m_value > 8 || n_value < 1 || n_value > 4 ||
			target_value < 1 || target_value > m_value { return -1 }
		m, n, target := int(m_value), int(n_value), int(target_value)
		if length != usize(3 + m + m*n) { return -1 }
		houses_at, costs_at := 3, 3 + m
		for index in 0 .. m {
			if input[houses_at+index] < 0 || input[houses_at+index] > n_value { return -1 }
		}
		for index in 0 .. m*n {
			if input[costs_at+index] < 0 || input[costs_at+index] > 100 { return -1 }
		}
		mut previous := [45]i64{}
		mut current := [45]i64{}
		for index in 0 .. 45 { previous[index] = 801 }
		first := input[houses_at]
		for color in 1 .. n+1 {
			if first == 0 || first == i64(color) {
				previous[color*9+1] = if first == 0 { input[costs_at+color-1] } else { 0 }
			}
		}
		for house in 1 .. m {
			for index in 0 .. 45 { current[index] = 801 }
			fixed := input[houses_at+house]
			for color in 1 .. n+1 {
				if fixed != 0 && fixed != i64(color) { continue }
				paint_cost := i64(0)
				if fixed == 0 { paint_cost = input[costs_at+house*n+color-1] }
				for groups in 1 .. target+1 {
					mut best := i64(801)
					for old_color in 1 .. n+1 {
						decrement := if old_color == color { 0 } else { 1 }
						old_groups := groups - decrement
						if old_groups >= 1 && previous[old_color*9+old_groups] < best {
							best = previous[old_color*9+old_groups]
						}
					}
					if best < 801 { current[color*9+groups] = best + paint_cost }
				}
			}
			for index in 0 .. 45 { previous[index] = current[index] }
		}
		mut answer := i64(801)
		for color in 1 .. n+1 {
			if previous[color*9+target] < answer { answer = previous[color*9+target] }
		}
		if answer >= 801 { return -1 }
		return answer
	}
}
