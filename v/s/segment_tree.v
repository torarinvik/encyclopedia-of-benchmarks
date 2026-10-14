module segment_tree

const max_items = 256
const max_operations = 512
const max_input_values = max_items + 3 + 3 * max_operations
const value_limit = 1_000_000
const query_offset = 256_000_001
const final_offset = 1_000_001

fn identity(mode i64) i64 {
	if mode == 1 { return value_limit + 1 }
	if mode == 2 { return -(value_limit + 1) }
	return 0
}

fn combine(mode i64, left i64, right i64) i64 {
	if mode == 1 { return if left < right { left } else { right } }
	if mode == 2 { return if left > right { left } else { right } }
	return left + right
}

@[export: 'segment_tree_benchmark']
pub fn segment_tree_benchmark(values &i64, length usize) i64 {
	if length < 3 || length > max_input_values { return -1 }
	mode := unsafe { values[0] }
	item_count_value := unsafe { values[1] }
	if mode < 0 || mode > 2 || item_count_value < 1 || item_count_value > max_items { return -1 }
	item_count := int(item_count_value)
	if int(length) < item_count + 3 { return -1 }
	operation_count_value := unsafe { values[item_count + 2] }
	if operation_count_value < 0 || operation_count_value > max_operations { return -1 }
	operation_count := int(operation_count_value)
	if int(length) != item_count + 3 + 3 * operation_count { return -1 }

	mut data := [max_items]i64{}
	for i in 0 .. item_count {
		value := unsafe { values[i + 2] }
		if value < -value_limit || value > value_limit { return -1 }
		data[i] = value
	}
	for operation in 0 .. operation_count {
		position := item_count + 3 + 3 * operation
		opcode := unsafe { values[position] }
		first := unsafe { values[position + 1] }
		second := unsafe { values[position + 2] }
		if opcode == 0 {
			if first < 0 || first >= item_count_value || second < -value_limit || second > value_limit { return -1 }
		} else if opcode == 1 {
			if first < 0 || second < first || second >= item_count_value { return -1 }
		} else { return -1 }
	}

	mut base := 1
	for base < item_count { base *= 2 }
	empty := identity(mode)
	mut tree := [2 * max_items]i64{}
	for i in 0 .. 2 * base { tree[i] = empty }
	for i in 0 .. item_count { tree[base + i] = data[i] }
	mut node := base
	for node > 1 {
		node--
		tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1])
	}

	mut checksum := i64(0)
	for operation in 0 .. operation_count {
		position := item_count + 3 + 3 * operation
		opcode := unsafe { values[position] }
		first := int(unsafe { values[position + 1] })
		if opcode == 0 {
			value := unsafe { values[position + 2] }
			data[first] = value
			node = base + first
			tree[node] = value
			for node > 1 {
				node /= 2
				tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1])
			}
		} else {
			mut left := base + first
			mut right := base + int(unsafe { values[position + 2] }) + 1
			mut result := empty
			for left < right {
				if left % 2 == 1 {
					result = combine(mode, result, tree[left])
					left++
				}
				if right % 2 == 1 {
					right--
					result = combine(mode, result, tree[right])
				}
				left /= 2
				right /= 2
			}
			checksum += i64(operation + 1) * (result + query_offset)
		}
	}
	for i in 0 .. item_count {
		checksum += i64(operation_count + i + 1) * (data[i] + final_offset)
	}
	return checksum
}
