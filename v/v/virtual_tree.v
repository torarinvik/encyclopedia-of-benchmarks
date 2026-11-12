module virtual_tree

const max_n = 32
const max_k = 32
const max_input = usize(66)
const max_virtual = 32
const max_candidates = 64
const max_words = 1 + 3 * max_virtual

fn lca(a0 int, b0 int, parent &int, depth &int) int {
	unsafe {
		mut a, mut b := a0, b0
		for depth[a] > depth[b] { a = parent[a] }
		for depth[b] > depth[a] { b = parent[b] }
		for a != b { a = parent[a]; b = parent[b] }
		return a
	}
}

fn is_ancestor(a int, b int, tin &int, tout &int) bool {
	unsafe { return tin[a] <= tin[b] && tin[b] < tout[a] }
}

fn sort_by_tin(items &int, count int, tin &int) {
	unsafe {
		for i in 1 .. count {
			value := items[i]
			mut j := i
			for j > 0 && tin[items[j - 1]] > tin[value] { items[j] = items[j - 1]; j-- }
			items[j] = value
		}
	}
}

fn put_word(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'virtual_tree']
pub fn virtual_tree(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 2 || length > max_input || unsafe { input == nil } { return -1 }
	unsafe {
		nv, kv := input[0], input[1]
		if nv < 1 || nv > max_n || kv < 0 || kv > max_k || kv > nv { return -1 }
		n, k := int(nv), int(kv)
		if int(length) != n + k + 1 { return -1 }

		mut parent := [max_n]int{}
		mut depth := [max_n]int{}
		mut children := [max_n][max_n]int{}
		mut child_count := [max_n]int{}
		for vertex in 1 .. n {
			p_value := input[vertex + 1]
			if p_value < 0 || p_value >= nv || p_value == i64(vertex) { return -1 }
			p := int(p_value)
			parent[vertex] = p
			children[p][child_count[p]] = vertex
			child_count[p]++
		}
		mut marks := [max_k]int{}
		for index in 0 .. k {
			mark_value := input[n + 1 + index]
			if mark_value < 0 || mark_value >= nv { return -1 }
			marks[index] = int(mark_value)
			for previous in 0 .. index {
				if marks[previous] == marks[index] { return -1 }
			}
		}

		mut tin := [max_n]int{init: -1}
		mut tout := [max_n]int{init: -1}
		mut node_stack := [max_n]int{}
		mut next_stack := [max_n]int{}
		mut timer, mut top, mut reached := 0, 1, 1
		node_stack[0] = 0
		tin[0] = timer
		timer++
		for top > 0 {
			frame := top - 1
			current := node_stack[frame]
			if next_stack[frame] == child_count[current] {
				tout[current] = timer
				top--
				continue
			}
			child := children[current][next_stack[frame]]
			next_stack[frame]++
			if tin[child] >= 0 { return -1 }
			tin[child] = timer
			timer++
			depth[child] = depth[current] + 1
			reached++
			node_stack[top] = child
			next_stack[top] = 0
			top++
		}
		if reached != n { return -1 }

		mut words := [max_words]i64{}
		mut word_count := 1
		if k == 0 {
			words[0] = 0
		} else {
			sort_by_tin(&marks[0], k, &tin[0])
			mut nodes := [max_candidates]int{}
			mut count := 0
			nodes[count] = 0
			count++
			for index in 0 .. k { nodes[count] = marks[index]; count++ }
			for index in 1 .. k {
				nodes[count] = lca(marks[index - 1], marks[index], &parent[0], &depth[0])
				count++
			}
			sort_by_tin(&nodes[0], count, &tin[0])
			mut unique := [max_virtual]int{}
			mut unique_count := 0
			for index in 0 .. count {
				if unique_count == 0 || unique[unique_count - 1] != nodes[index] {
					unique[unique_count] = nodes[index]
					unique_count++
				}
			}
			words[0] = i64(unique_count)
			mut stack := [max_virtual]int{}
			mut stack_size := 0
			for index in 0 .. unique_count {
				vertex := unique[index]
				for stack_size > 0 && !is_ancestor(stack[stack_size - 1], vertex, &tin[0], &tout[0]) { stack_size-- }
				mut virtual_parent := vertex
				if stack_size > 0 { virtual_parent = stack[stack_size - 1] }
				words[word_count] = i64(vertex)
				words[word_count + 1] = i64(virtual_parent)
				words[word_count + 2] = i64(depth[vertex] - depth[virtual_parent])
				word_count += 3
				stack[stack_size] = vertex
				stack_size++
			}
		}
		output_bytes := word_count * 8
		if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. word_count { put_word(&output[0], index * 8, words[index]) }
		return i64(output_bytes)
	}
}
