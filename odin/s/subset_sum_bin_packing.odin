package subset_sum_bin_packing

import "core:c"

MAX_ITEMS :: 16
MAX_CAPACITY :: 32
MAX_INPUT_LENGTH :: 19

@(export)
subset_sum_bin_packing :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	raw_count := input[0]
	raw_capacity := input[1]
	if raw_count < 1 || raw_count > MAX_ITEMS || raw_capacity < 1 || raw_capacity > MAX_CAPACITY do return -1
	count := int(raw_count)
	capacity := int(raw_capacity)
	if length != c.size_t(count + 2) do return -1

	var remaining_size: [MAX_ITEMS]i64
	var remaining_item: [MAX_ITEMS]int
	var assigned_bin: [MAX_ITEMS]i64
	for index := 0; index < count; index += 1 {
		size := input[index+2]
		if size < 1 || size > raw_capacity do return -1
		remaining_size[index] = size
		remaining_item[index] = index
	}

	remaining_count := count
	bin_count: i64 = 0
	for remaining_count > 0 {
		var reachable: [MAX_ITEMS+1][MAX_CAPACITY+1]bool
		reachable[remaining_count][0] = true
		for row := remaining_count; row > 0; {
			row -= 1
			size := int(remaining_size[row])
			for sum := 0; sum <= capacity; sum += 1 {
				reachable[row][sum] = reachable[row+1][sum]
				if sum >= size && reachable[row+1][sum-size] do reachable[row][sum] = true
			}
		}

		target := capacity
		for target > 0 && !reachable[0][target] do target -= 1
		var selected: [MAX_ITEMS]bool
		needed := target
		for item := 0; item < remaining_count; item += 1 {
			size := int(remaining_size[item])
			if size <= needed && reachable[item+1][needed-size] {
				selected[item] = true
				needed -= size
				assigned_bin[remaining_item[item]] = bin_count
			}
		}

		survivors := 0
		for item := 0; item < remaining_count; item += 1 {
			if !selected[item] {
				remaining_size[survivors] = remaining_size[item]
				remaining_item[survivors] = remaining_item[item]
				survivors += 1
			}
		}
		remaining_count = survivors
		bin_count += 1
	}

	checksum := bin_count * 10000
	for index := 0; index < count; index += 1 {
		checksum += i64(index+1) * (assigned_bin[index] + 1)
	}
	return checksum
}
