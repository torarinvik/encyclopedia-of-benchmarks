package inorder_successor_of_bst

import "core:c"

MAX_NODES :: 64
MAX_INPUT_LENGTH :: c.size_t(67)

@(export)
inorder_successor_of_bst :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	count_value, target := input[0], input[1]
	if count_value < 0 || count_value > MAX_NODES || target < 1 || target > 2_147_483_647 do return -1
	count := int(count_value)
	if length != c.size_t(count + 2) do return -1

	var keys: [MAX_NODES]i64
	var left, right: [MAX_NODES]int
	for index := 0; index < count; index += 1 {
		key := input[index+2]
		if key < 1 || key > 2_147_483_647 do return -1
		for previous := 0; previous < index; previous += 1 {
			if keys[previous] == key do return -1
		}
		keys[index] = key
		left[index], right[index] = -1, -1
	}

	root := -1
	for index := 0; index < count; index += 1 {
		if root < 0 {
			root = index
			continue
		}
		current := root
		for {
			if keys[index] <= keys[current] {
				if left[current] < 0 {
					left[current] = index
					break
				}
				current = left[current]
			} else {
				if right[current] < 0 {
					right[current] = index
					break
				}
				current = right[current]
			}
		}
	}

	current := root
	for current >= 0 && keys[current] != target {
		if target > keys[current] { current = right[current] } else { current = left[current] }
	}
	if current < 0 do return 0
	if right[current] >= 0 {
		successor := right[current]
		for left[successor] >= 0 { successor = left[successor] }
		return keys[successor]
	}
	successor, ancestor := -1, root
	for ancestor >= 0 && ancestor != current {
		if keys[current] < keys[ancestor] {
			successor = ancestor
			ancestor = left[ancestor]
		} else {
			ancestor = right[ancestor]
		}
	}
	if successor < 0 do return 0
	return keys[successor]
}
