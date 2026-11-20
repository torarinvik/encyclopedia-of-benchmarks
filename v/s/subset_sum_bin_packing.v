module subset_sum_bin_packing

const max_items = 16
const max_capacity = 32
const max_input_length = 19

@[export: 'subset_sum_bin_packing']
pub fn subset_sum_bin_packing(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		raw_count := input[0]
		raw_capacity := input[1]
		if raw_count < 1 || raw_count > max_items || raw_capacity < 1 || raw_capacity > max_capacity { return -1 }
		count := int(raw_count)
		capacity := int(raw_capacity)
		if int(length) != count + 2 { return -1 }

		mut remaining_size := [max_items]i64{}
		mut remaining_item := [max_items]int{}
		mut assigned_bin := [max_items]i64{}
		for index in 0 .. count {
			size := input[index + 2]
			if size < 1 || size > raw_capacity { return -1 }
			remaining_size[index] = size
			remaining_item[index] = index
		}

		mut remaining_count := count
		mut bin_count := i64(0)
		for remaining_count > 0 {
			mut reachable := [max_items + 1][max_capacity + 1]bool{}
			reachable[remaining_count][0] = true
			mut row := remaining_count
			for row > 0 {
				row--
				size := int(remaining_size[row])
				for sum in 0 .. capacity + 1 {
					reachable[row][sum] = reachable[row + 1][sum]
					if sum >= size && reachable[row + 1][sum - size] {
						reachable[row][sum] = true
					}
				}
			}

			mut target := capacity
			for target > 0 && !reachable[0][target] { target-- }
			mut selected := [max_items]bool{}
			mut needed := target
			for item in 0 .. remaining_count {
				size := int(remaining_size[item])
				if size <= needed && reachable[item + 1][needed - size] {
					selected[item] = true
					needed -= size
					assigned_bin[remaining_item[item]] = bin_count
				}
			}

			mut survivors := 0
			for item in 0 .. remaining_count {
				if !selected[item] {
					remaining_size[survivors] = remaining_size[item]
					remaining_item[survivors] = remaining_item[item]
					survivors++
				}
			}
			remaining_count = survivors
			bin_count++
		}

		mut checksum := bin_count * 10000
		for index in 0 .. count {
			checksum += i64(index + 1) * (assigned_bin[index] + 1)
		}
		return checksum
	}
}
