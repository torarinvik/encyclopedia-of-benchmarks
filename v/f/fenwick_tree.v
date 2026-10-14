module fenwick_tree

const max_items = 256
const max_operations = 512
const max_input_values = 2 + 3 * max_operations
const value_limit = 1_000_000

fn lowbit(index int) int { return index & -index }

fn prefix_sum(tree []i64, count int) i64 {
	mut index := count
	mut total := i64(0)
	for index > 0 {
		total += tree[index]
		index -= lowbit(index)
	}
	return total
}

@[export: 'fenwick_tree_benchmark']
pub fn fenwick_tree_benchmark(values &i64, length usize) i64 {
	if length < 2 || length > max_input_values { return -1 }
	item_count_value := unsafe { values[0] }
	operation_count_value := unsafe { values[1] }
	if item_count_value < 1 || item_count_value > max_items { return -1 }
	if operation_count_value < 0 || operation_count_value > max_operations { return -1 }
	item_count := int(item_count_value)
	operation_count := int(operation_count_value)
	query_offset := i64(max_items) * i64(max_operations) * i64(value_limit) + 1
	final_offset := i64(512) * i64(value_limit) + 1
	if int(length) != 2 + 3 * operation_count { return -1 }
	for operation in 0 .. operation_count {
		position := 2 + 3 * operation
		opcode := unsafe { values[position] }
		first := unsafe { values[position + 1] }
		second := unsafe { values[position + 2] }
		if opcode == 0 {
			if first < 0 || first >= item_count_value || second < -value_limit || second > value_limit { return -1 }
		} else if opcode == 1 {
			if first < 0 || second < first || second >= item_count_value { return -1 }
		} else { return -1 }
	}

	mut data := []i64{len: max_items}
	mut tree := []i64{len: max_items + 1}
	mut checksum := i64(0)
	for operation in 0 .. operation_count {
		position := 2 + 3 * operation
		opcode := unsafe { values[position] }
		first := int(unsafe { values[position + 1] })
		second := unsafe { values[position + 2] }
		if opcode == 0 {
			data[first] += second
			mut index := first + 1
			for index <= item_count {
				tree[index] += second
				index += lowbit(index)
			}
		} else {
			right := int(second)
			result := prefix_sum(tree, right + 1) - prefix_sum(tree, first)
			checksum += i64(operation + 1) * (result + query_offset)
		}
	}
	for i in 0 .. item_count {
		checksum += i64(operation_count + i + 1) * (data[i] + final_offset)
	}
	return checksum
}
