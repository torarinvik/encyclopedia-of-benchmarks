const max_items = 16
const max_operations = 32
const max_input_length = 99

fn ufe_find(mut parent [max_items]i64, item int) int {
	mut root := item
	for parent[root] >= 0 { root = int(parent[root]) }
	mut current := item
	for current != root {
		next_item := int(parent[current])
		parent[current] = i64(root)
		current = next_item
	}
	return root
}

fn ufe_component_mask(successor [max_items]i64, start int) i64 {
	mut mask := u64(0)
	mut item := start
	for {
		mask |= u64(1) << u64(item)
		item = int(successor[item])
		if item == start { break }
	}
	return i64(mask)
}

@[export: 'union_find_enumerate']
pub fn union_find_enumerate(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		item_count_value, operation_count_value := input[0], input[1]
		if item_count_value < 1 || item_count_value > max_items || operation_count_value < 0 || operation_count_value > max_operations { return -1 }
		item_count, operation_count := int(item_count_value), int(operation_count_value)
		if length != usize(2 + 3 * operation_count) { return -1 }

		for operation in 0 .. operation_count {
			position := 2 + 3 * operation
			opcode, first, second := input[position], input[position + 1], input[position + 2]
			if opcode == 0 {
				if first < 0 || first >= item_count_value || second < 0 || second >= item_count_value { return -1 }
			} else if opcode == 1 {
				if first < 0 || first >= item_count_value || second != 0 { return -1 }
			} else { return -1 }
		}

		mut parent := [max_items]i64{init: -1}
		mut successor := [max_items]i64{}
		for item in 0 .. item_count { successor[item] = i64(item) }
		mut checksum := i64(0)
		for operation in 0 .. operation_count {
			position := 2 + 3 * operation
			opcode := input[position]
			first := int(input[position + 1])
			mut observed := i64(0)
			if opcode == 0 {
				mut left := ufe_find(mut parent, first)
				mut right := ufe_find(mut parent, int(input[position + 2]))
				if left != right {
					if parent[left] > parent[right] { left, right = right, left }
					parent[left] += parent[right]
					parent[right] = i64(left)
					temporary := successor[left]
					successor[left] = successor[right]
					successor[right] = temporary
					observed = 1
				}
			} else {
				observed = ufe_component_mask(successor, first)
			}
			checksum += i64(operation + 1) * (observed + 1)
		}
		return checksum
	}
}
