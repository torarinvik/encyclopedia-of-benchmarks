module pisinger_bounded_weight_subset_sum

const max_items = 32
const max_target = 256
const max_weight = 12
const max_parseable_input_length = 35
const max_states = 2 * max_weight

@[export: 'pisinger_bounded_weight_subset_sum']
pub fn pisinger_bounded_weight_subset_sum(input &i64, length usize) i64 {
	if input == nil || length < 2 || length > max_parseable_input_length { return -1 }
	unsafe {
		n_value := input[0]
		target_value := input[1]
		if n_value < 0 || n_value > max_items || target_value < 0 || target_value > max_target { return -1 }
		n := int(n_value)
		if length != n + 2 { return -1 }

		mut width := 0
		for index := 0; index < n; index++ {
			weight := input[index + 2]
			if weight < 1 || weight > max_weight { return -1 }
			if int(weight) > width { width = int(weight) }
		}
		if n == 0 { return 0 }

		target := int(target_value)
		mut prefix_sum := 0
		mut break_index := 0
		for break_index < n && prefix_sum + int(input[break_index + 2]) <= target {
			prefix_sum += int(input[break_index + 2])
			break_index++
		}
		if break_index == n { return i64(prefix_sum) }

		mut previous := []i32{len: 2 * width, init: -1}
		mut current := []i32{len: 2 * width, init: -1}
		previous[prefix_sum + width - target - 1] = i32(break_index)
		for item := break_index; item < n; item++ {
			for slot := 0; slot < 2 * width; slot++ { current[slot] = previous[slot] }
			weight := int(input[item + 2])
			for slot := 0; slot < width; slot++ {
				destination := slot + weight
				if previous[slot] > current[destination] { current[destination] = previous[slot] }
			}
			slot := 2 * width - 1
			for slot >= width {
				first_item := previous[slot]
				if first_item < 0 { first_item = 0 }
				stop_item := current[slot]
				for removed := first_item; removed < stop_item; removed++ {
					reduced := slot - int(input[int(removed) + 2])
					if removed > current[reduced] { current[reduced] = removed }
				}
				slot--
			}
			for slot := 0; slot < 2 * width; slot++ { previous[slot] = current[slot] }
		}

		low := 0
		if target >= width { low = target - width + 1 }
		mass := target
		for mass >= low {
			if previous[mass + width - target - 1] >= 0 { return i64(mass) }
			if mass == 0 { break }
			mass--
		}
		return 0
	}
}
