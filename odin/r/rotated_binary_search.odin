package rotated_binary_search

import "core:c"

@(export)
rotated_binary_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 do return -2
	if input[0] < 0 || input[0] > 256 do return -2
	n := int(input[0])
	if length != c.size_t(n + 2) do return -2
	if n == 0 do return -1
	key := input[n + 1]
	if key < -2_147_483_648 || key > 2_147_483_647 do return -2
	drops := 0
	for index := 0; index < n; index += 1 {
		if input[index + 1] < -2_147_483_648 || input[index + 1] > 2_147_483_647 do return -2
		if index > 0 && input[index] > input[index + 1] { drops += 1 }
	}
	if drops > 1 || (drops == 1 && input[n] > input[1]) do return -2
	left := 0
	right := n - 1
	for left <= right {
		middle := left + (right - left) / 2
		mid_value := input[middle + 1]
		if key == mid_value do return i64(middle)
		if input[left + 1] == mid_value && mid_value == input[right + 1] {
			left += 1
			if right == 0 do break
			right -= 1
			continue
		}
		if input[left + 1] <= mid_value {
			if input[left + 1] <= key && key < mid_value {
				if middle == 0 do break
				right = middle - 1
			} else { left = middle + 1 }
		} else if mid_value < key && key <= input[right + 1] { left = middle + 1 }
		else {
			if middle == 0 do break
			right = middle - 1
		}
	}
	return -1
}
