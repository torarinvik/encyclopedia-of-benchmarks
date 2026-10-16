package bfprt

import "core:c"

MAX_SIZE :: 1024
INVALID :: i64(-2_147_483_649)

swap_values :: proc(values: [^]i32, left, right: int) {
	temporary := values[left]
	values[left] = values[right]
	values[right] = temporary
}

select_bfprt :: proc(values: [^]i32, left_value, right_value, rank: int) -> i32 {
	left, right := left_value, right_value
	for left < right {
		count := right - left + 1
		groups := (count + 4) / 5
		for group := 0; group < groups; group += 1 {
			group_left := left + group * 5
			group_right := group_left + 4
			if group_right > right do group_right = right
			for index := group_left + 1; index <= group_right; index += 1 {
				cursor := index
				for cursor > group_left && values[cursor - 1] > values[cursor] {
					swap_values(values, cursor - 1, cursor)
					cursor -= 1
				}
			}
			median := group_left + (group_right - group_left + 1) / 2
			swap_values(values, left + group, median)
		}

		pivot := values[left]
		if groups > 1 {
			pivot = select_bfprt(values, left, left + groups - 1, left + groups / 2)
		}
		less, current, greater := left, left, right + 1
		for current < greater {
			if values[current] < pivot {
				swap_values(values, less, current)
				less += 1
				current += 1
			} else if values[current] > pivot {
				greater -= 1
				swap_values(values, current, greater)
			} else {
				current += 1
			}
		}
		if rank < less {
			right = less - 1
		} else if rank >= greater {
			left = greater
		} else {
			return values[rank]
		}
	}
	return values[left]
}

@(export)
bfprt :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 do return INVALID
	nv, rank_value := input[0], input[1]
	if nv < 1 || nv > MAX_SIZE do return INVALID
	n := int(nv)
	if length != c.size_t(n + 2) || rank_value < 1 || rank_value > nv do return INVALID
	var values: [MAX_SIZE]i32
	for index := 0; index < n; index += 1 {
		value := input[index + 2]
		if value < -2_147_483_648 || value > 2_147_483_647 do return INVALID
		values[index] = i32(value)
	}
	return i64(select_bfprt(&values[0], 0, n - 1, int(rank_value - 1)))
}
