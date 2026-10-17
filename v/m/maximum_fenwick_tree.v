module maximum_fenwick_tree

@[export: 'maximum_fenwick_tree']
pub fn maximum_fenwick_tree(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 194 { return -1 }
	if unsafe { input[0] < 1 || input[0] > 64 || input[1] < 0 || input[1] > 64 } { return -1 }
	size := int(unsafe { input[0] })
	op_count := int(unsafe { input[1] })
	if int(length) != 2 + 3 * op_count { return -1 }
	mut values := [64]i32{}
	mut tree := [64]i32{}
	mut results := [64]i64{}
	mut result_count := 0
	for op in 0 .. op_count {
		pos := 2 + 3 * op
		opcode := unsafe { input[pos] }
		first := unsafe { input[pos + 1] }
		second := unsafe { input[pos + 2] }
		if opcode == 0 {
			if first < 0 || first >= i64(size) || second < 0 || second > 2147483647 { return -1 }
			mut index := int(first)
			old_value := values[index]
			value := i32(second)
			values[index] = value
			for index < size {
				old_max := tree[index]
				if value > old_max {
					tree[index] = value
				} else if old_value == old_max {
					left := int((index & (index + 1)))
					mut maximum := value
					mut child := index - 1
					for child >= left {
						maximum = max(maximum, tree[child])
						if maximum == old_max { break }
						child = (child & (child + 1)) - 1
					}
					tree[index] = maximum
					if maximum == old_max { break }
				} else { break }
				index |= index + 1
			}
		} else if opcode == 1 {
			if first < 0 || first > second || second > i64(size) { return -1 }
			mut maximum := i32(0)
			mut right := int(second - 1)
			for first <= i64(right) {
				current_left := right & (right + 1)
				if first <= i64(current_left) {
					maximum = max(maximum, tree[right])
					right = current_left - 1
				} else {
					maximum = max(maximum, values[right])
					right--
				}
			}
			results[result_count] = i64(maximum)
			result_count++
		} else { return -1 }
	}
	bytes := result_count * 8
	if unsafe { output == nil } || output_capacity < usize(bytes) { return -2 }
	for i in 0 .. result_count {
		bits := u64(results[i])
		for b in 0 .. 8 {
			unsafe { output[8 * i + b] = u8((bits >> (8 * b)) & 255) }
		}
	}
	return i64(bytes)
}
