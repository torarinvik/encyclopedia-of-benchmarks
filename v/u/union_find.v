module union_find

const max_items = 256
const max_operations = 512
const max_input_values = 2 + 3 * max_operations
const observed_offset = 1_000_003

fn find_root(mut parent []i64, item int) int {
	mut current := item
	for parent[current] != i64(current) {
		parent[current] = parent[int(parent[current])]
		current = int(parent[current])
	}
	return current
}

@[export: 'union_find_benchmark']
pub fn union_find_benchmark(values &i64, length usize) i64 {
	if length < 2 || length > max_input_values { return -1 }
	item_count_value := unsafe { values[0] }
	operation_count_value := unsafe { values[1] }
	if item_count_value < 1 || item_count_value > max_items { return -1 }
	if operation_count_value < 0 || operation_count_value > max_operations { return -1 }
	item_count := int(item_count_value)
	operation_count := int(operation_count_value)
	if int(length) != 2 + 3 * operation_count { return -1 }

	for operation in 0 .. operation_count {
		position := 2 + 3 * operation
		opcode := unsafe { values[position] }
		first := unsafe { values[position + 1] }
		second := unsafe { values[position + 2] }
		if opcode == 0 || opcode == 1 {
			if first < 0 || first >= item_count_value || second < 0 || second >= item_count_value { return -1 }
		} else if opcode == 2 {
			if first != 0 || second != 0 { return -1 }
		} else { return -1 }
	}

	mut parent := []i64{len: max_items}
	mut set_size := []i64{len: max_items}
	for i in 0 .. item_count {
		parent[i] = i64(i)
		set_size[i] = 1
	}
	mut components := item_count
	mut connected_pairs := i64(0)
	mut checksum := i64(0)
	for operation in 0 .. operation_count {
		position := 2 + 3 * operation
		opcode := unsafe { values[position] }
		first := int(unsafe { values[position + 1] })
		second := int(unsafe { values[position + 2] })
		mut observed := i64(0)
		if opcode == 0 {
			first_root := find_root(mut parent, first)
			second_root := find_root(mut parent, second)
			if first_root != second_root {
				connected_pairs += set_size[first_root] * set_size[second_root]
				if set_size[first_root] < set_size[second_root] {
					parent[first_root] = i64(second_root)
					set_size[second_root] += set_size[first_root]
				} else {
					parent[second_root] = i64(first_root)
					set_size[first_root] += set_size[second_root]
				}
				components--
				observed = 1
			}
		} else if opcode == 1 {
			if find_root(mut parent, first) == find_root(mut parent, second) { observed = 1 }
		} else {
			observed = i64(components)
		}
		checksum += i64(operation + 1) * (observed + observed_offset)
	}
	return checksum + connected_pairs
}
