module vertex_add_subtree_sum

const max_n = 128
const max_q = 256
const max_input_values = usize(2 * max_n + 1 + 3 * max_q)
const max_value = i64(1_000_000)

fn fenwick_add(mut tree &i64, n int, position int, delta i64) {
	unsafe {
		mut index := position + 1
		for index <= n {
			tree[index] += delta
			index += index & -index
		}
	}
}

fn fenwick_prefix(tree &i64, count int) i64 {
	unsafe {
		mut total := i64(0)
		mut index := count
		for index > 0 {
			total += tree[index]
			index -= index & -index
		}
		return total
	}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'vertex_add_subtree_sum']
pub fn vertex_add_subtree_sum(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values { return -1 }
	unsafe {
		nv, qv := input[0], input[1]
		if nv < 1 || nv > max_n || qv < 0 || qv > max_q { return -1 }
		n, q := int(nv), int(qv)
		if length != usize(2 * n + 1 + 3 * q) { return -1 }

		mut values := [max_n]i64{}
		mut first_child := [max_n]i64{init: -1}
		mut next_sibling := [max_n]i64{init: -1}
		for vertex in 0 .. n {
			values[vertex] = input[2 + vertex]
			if values[vertex] < 0 || values[vertex] > max_value { return -1 }
		}
		parent_start := 2 + n
		for vertex in 1 .. n {
			parent_value := input[parent_start + vertex - 1]
			if parent_value < 0 || parent_value >= i64(vertex) { return -1 }
			parent := int(parent_value)
			next_sibling[vertex] = first_child[parent]
			first_child[parent] = i64(vertex)
		}

		mut tin := [max_n]int{}
		mut tout := [max_n]int{}
		mut stack_node := [max_n]int{}
		mut stack_next_child := [max_n]i64{}
		mut timer := 0
		mut top := 1
		stack_node[0], stack_next_child[0] = 0, first_child[0]
		tin[0] = timer
		timer++
		for top > 0 {
			frame := top - 1
			child_value := stack_next_child[frame]
			if child_value < 0 {
				tout[stack_node[frame]] = timer
				top--
				continue
			}
			child := int(child_value)
			stack_next_child[frame] = next_sibling[child]
			tin[child] = timer
			timer++
			stack_node[top], stack_next_child[top] = child, first_child[child]
			top++
		}

		mut fenwick := [max_n + 1]i64{}
		for vertex in 0 .. n { fenwick_add(&fenwick[0], n, tin[vertex], values[vertex]) }
		mut answers := [max_q]i64{}
		mut answer_count := 0
		operation_start := parent_start + n - 1
		for operation_index in 0 .. q {
			offset := operation_start + 3 * operation_index
			kind, vertex_value, operand := input[offset], input[offset + 1], input[offset + 2]
			if kind == 0 {
				if vertex_value < 0 || vertex_value >= nv || operand < 0 || operand > max_value { return -1 }
				vertex := int(vertex_value)
				values[vertex] += operand
				fenwick_add(&fenwick[0], n, tin[vertex], operand)
			} else if kind == 1 {
				if vertex_value < 0 || vertex_value >= nv || operand != 0 { return -1 }
				vertex := int(vertex_value)
				answers[answer_count] = fenwick_prefix(&fenwick[0], tout[vertex]) -
					fenwick_prefix(&fenwick[0], tin[vertex])
				answer_count++
			} else { return -1 }
		}

		output_bytes := 8 * answer_count
		if output_bytes > 0 && (output == nil || capacity < usize(output_bytes)) { return -2 }
		for index in 0 .. answer_count { store_i64_le(output, 8 * index, answers[index]) }
		return i64(output_bytes)
	}
}
