module range_parallel_unionfind

const max_n = 64
const max_q = 64
const max_levels = 6
const max_input_values = 2 + max_n + 3 * max_q
const modulus = i64(998244353)

fn normalize(value i64) i64 {
	mut reduced := value % modulus
	if reduced < 0 {
		reduced += modulus
	}
	return reduced
}

fn find_root(mut parent []int, level int, item int) int {
	index := level * max_n + item
	if parent[index] != item {
		parent[index] = find_root(mut parent, level, parent[index])
	}
	return parent[index]
}

fn merge_inner(level int, left int, right int, mut parent []int, mut set_size []int,
	mut weight []i64, mut pair_sum i64) {
	mut root_left := find_root(mut parent, level, left)
	mut root_right := find_root(mut parent, level, right)
	if root_left == root_right {
		return
	}
	mut left_index := level * max_n + root_left
	mut right_index := level * max_n + root_right
	if set_size[left_index] < set_size[right_index] {
		root_left, root_right = root_right, root_left
		left_index, right_index = right_index, left_index
	}
	parent[level * max_n + root_right] = root_left
	set_size[left_index] += set_size[right_index]
	if level == 0 {
		pair_sum = normalize(pair_sum + weight[root_left] * weight[root_right])
		weight[root_left] = normalize(weight[root_left] + weight[root_right])
		return
	}
	half := 1 << (level - 1)
	merge_inner(level - 1, left, right, mut parent, mut set_size, mut weight, mut pair_sum)
	merge_inner(level - 1, left + half, right + half, mut parent, mut set_size, mut weight, mut pair_sum)
}

fn floor_log2(value int) int {
	mut level := 0
	mut remaining := value
	for remaining > 1 {
		remaining >>= 1
		level++
	}
	return level
}

fn merge_ranges(length int, left int, right int, mut parent []int, mut set_size []int,
	mut weight []i64, mut pair_sum i64) {
	if length == 0 {
		return
	}
	level := floor_log2(length - 1)
	block := 1 << level
	merge_inner(level, left, right, mut parent, mut set_size, mut weight, mut pair_sum)
	merge_inner(level, left + length - block, right + length - block,
		mut parent, mut set_size, mut weight, mut pair_sum)
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'range_parallel_unionfind']
pub fn range_parallel_unionfind(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 6 || length > max_input_values {
		return -1
	}
	n_value := unsafe { input[0] }
	q_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_n || q_value < 1 || q_value > max_q {
		return -1
	}
	n := int(n_value)
	q := int(q_value)
	if length != usize(2 + n + 3 * q) {
		return -1
	}
	for item in 0 .. n {
		value := unsafe { input[2 + item] }
		if value < 0 || value >= modulus {
			return -1
		}
	}
	operations_at := 2 + n
	for operation in 0 .. q {
		position := operations_at + 3 * operation
		span := unsafe { input[position] }
		left := unsafe { input[position + 1] }
		right := unsafe { input[position + 2] }
		if span < 0 || span > n_value || left < 0 || right < 0 ||
			left > n_value - span || right > n_value - span {
			return -1
		}
	}
	required := 8 * q
	if unsafe { output == nil } || capacity < usize(required) {
		return -2
	}

	mut parent := []int{len: max_levels * max_n}
	mut set_size := []int{len: max_levels * max_n}
	mut weight := []i64{len: max_n}
	for level in 0 .. max_levels {
		block := 1 << level
		if block > n {
			break
		}
		for start in 0 .. n - block + 1 {
			index := level * max_n + start
			parent[index] = start
			set_size[index] = 1
		}
	}
	for item in 0 .. n {
		weight[item] = unsafe { input[2 + item] }
	}
	mut pair_sum := i64(0)
	for operation in 0 .. q {
		position := operations_at + 3 * operation
		span := int(unsafe { input[position] })
		left := int(unsafe { input[position + 1] })
		right := int(unsafe { input[position + 2] })
		merge_ranges(span, left, right, mut parent, mut set_size, mut weight, mut pair_sum)
		store_i64_le(mut output, 8 * operation, pair_sum)
	}
	return i64(required)
}
