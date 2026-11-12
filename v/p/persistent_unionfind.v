module persistent_unionfind

const max_n = 64
const max_q = 64
const max_input_values = 2 + 4 * max_q

fn find_root(parent []int, item int) int {
	mut current := item
	for parent[current] != current {
		current = parent[current]
	}
	return current
}

fn visit_version(node int, kind []i64, u []i64, v []i64, first_child []int,
	next_sibling []int, mut parent []int, mut set_size []int, mut answer []i64,
	mut history_child []int, mut history_root []int, mut history_size []int,
	mut history_count int) {
	saved_history := history_count
	if node != 0 {
		operation := node - 1
		if kind[operation] == 0 {
			mut root_u := find_root(parent, int(u[operation]))
			mut root_v := find_root(parent, int(v[operation]))
			if root_u == root_v {
				history_child[history_count] = -1
				history_root[history_count] = -1
				history_size[history_count] = 0
			} else {
				if set_size[root_u] > set_size[root_v] {
					root_u, root_v = root_v, root_u
				}
				history_child[history_count] = root_u
				history_root[history_count] = root_v
				history_size[history_count] = set_size[root_v]
				parent[root_u] = root_v
				set_size[root_v] += set_size[root_u]
			}
			history_count++
		} else {
			if find_root(parent, int(u[operation])) == find_root(parent, int(v[operation])) {
				answer[node] = 1
			} else {
				answer[node] = 0
			}
		}
	}
	mut child := first_child[node]
	for child >= 0 {
		visit_version(child, kind, u, v, first_child, next_sibling, mut parent,
			mut set_size, mut answer, mut history_child, mut history_root,
			mut history_size, mut history_count)
		child = next_sibling[child - 1]
	}
	for history_count > saved_history {
		history_count--
		changed_child := history_child[history_count]
		if changed_child >= 0 {
			root := history_root[history_count]
			parent[changed_child] = changed_child
			set_size[root] = history_size[history_count]
		}
	}
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

@[export: 'persistent_unionfind']
pub fn persistent_unionfind(input &i64, length usize, mut output &u8, capacity usize) i64 {
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
	if length != usize(2 + 4 * q) {
		return -1
	}

	mut kind := []i64{len: max_q}
	mut u := []i64{len: max_q}
	mut v := []i64{len: max_q}
	mut first_child := []int{len: max_q + 1, init: -1}
	mut next_sibling := []int{len: max_q}
	mut answer := []i64{len: max_q + 1}
	mut query_count := 0
	for operation in 0 .. q {
		offset := 2 + 4 * operation
		kind[operation] = unsafe { input[offset] }
		version := unsafe { input[offset + 1] }
		u[operation] = unsafe { input[offset + 2] }
		v[operation] = unsafe { input[offset + 3] }
		if (kind[operation] != 0 && kind[operation] != 1) || version < -1 ||
			version >= i64(operation) || u[operation] < 0 || u[operation] >= n_value ||
			v[operation] < 0 || v[operation] >= n_value {
			return -1
		}
		if version >= 0 && kind[int(version)] != 0 {
			return -1
		}
		if kind[operation] == 1 {
			query_count++
		}
		parent_node := int(version + 1)
		next_sibling[operation] = first_child[parent_node]
		first_child[parent_node] = operation + 1
	}

	required := 8 * query_count
	if unsafe { output == nil } || capacity < usize(required) {
		return -2
	}
	mut parent := []int{len: max_n}
	mut set_size := []int{len: max_n, init: 1}
	for item in 0 .. n {
		parent[item] = item
	}
	mut history_child := []int{len: max_q}
	mut history_root := []int{len: max_q}
	mut history_size := []int{len: max_q}
	mut history_count := 0
	visit_version(0, kind, u, v, first_child, next_sibling, mut parent, mut set_size,
		mut answer, mut history_child, mut history_root, mut history_size, mut history_count)
	mut written := 0
	for operation in 0 .. q {
		if kind[operation] == 1 {
			store_i64_le(mut output, written, answer[operation + 1])
			written += 8
		}
	}
	return i64(written)
}
