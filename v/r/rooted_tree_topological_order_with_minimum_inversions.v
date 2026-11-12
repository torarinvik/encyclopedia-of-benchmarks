module rooted_tree_topological_order_with_minimum_inversions

const max_n = 12
const max_input_values = 3 * max_n + 1
const max_output_words = max_n + 1
const max_weight = i64(1_000_000)

fn compare_ratio(left_c i64, left_d i64, right_c i64, right_d i64) int {
	left_zero := left_c == 0 && left_d == 0
	right_zero := right_c == 0 && right_d == 0
	if left_zero != right_zero {
		if left_zero { return -1 }
		return 1
	}
	lhs := left_c * right_d
	rhs := left_d * right_c
	if lhs > rhs { return 1 }
	if lhs < rhs { return -1 }
	return 0
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

@[export: 'rooted_tree_topological_order_with_minimum_inversions']
pub fn rooted_tree_topological_order_with_minimum_inversions(values &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 3 || length > usize(max_input_values) { return -1 }
	unsafe {
		if values == nil { return -1 }
		n_value := values[0]
		if n_value < 1 || n_value > max_n || length != usize(3 * n_value) { return -1 }
		n := int(n_value)

		mut tree_parent := [max_n]int{}
		for vertex in 1 .. n {
			p := values[vertex]
			if p < 0 || p >= i64(vertex) { return -1 }
			tree_parent[vertex] = int(p)
		}

		mut original_c := [max_n]i64{}
		mut original_d := [max_n]i64{}
		mut aggregate_c := [max_n]i64{}
		mut aggregate_d := [max_n]i64{}
		mut sum_c := i64(0)
		mut sum_d := i64(0)
		for vertex in 0 .. n {
			c := values[n + vertex]
			d := values[2 * n + vertex]
			if c < 0 || c > max_weight || d < 0 || d > max_weight { return -1 }
			sum_c += c
			sum_d += d
			if sum_c > max_weight || sum_d > max_weight { return -1 }
			original_c[vertex] = c
			original_d[vertex] = d
			aggregate_c[vertex] = c
			aggregate_d[vertex] = d
		}

		mut dsu_parent := [max_n]int{}
		mut component_label := [max_n]int{}
		mut active := [max_n]bool{}
		mut link := [max_n]int{}
		for vertex in 0 .. n {
			dsu_parent[vertex] = vertex
			component_label[vertex] = vertex
			active[vertex] = vertex != 0
			link[vertex] = vertex
		}

		for _ in 0 .. n - 1 {
			mut selected := -1
			for candidate in 1 .. n {
				if !active[candidate] { continue }
				if selected < 0 { selected = candidate; continue }
				comparison := compare_ratio(aggregate_c[candidate], aggregate_d[candidate],
					aggregate_c[selected], aggregate_d[selected])
				if comparison > 0 || (comparison == 0 && candidate > selected) { selected = candidate }
			}
			if selected < 0 { return -1 }
			mut parent_component := tree_parent[selected]
			for dsu_parent[parent_component] != parent_component { parent_component = dsu_parent[parent_component] }
			target := component_label[parent_component]
			mut child_component := selected
			for dsu_parent[child_component] != child_component { child_component = dsu_parent[child_component] }
			if child_component == parent_component { return -1 }
			aggregate_c[target] += aggregate_c[selected]
			aggregate_d[target] += aggregate_d[selected]
			dsu_parent[child_component] = parent_component
			component_label[parent_component] = target
			active[selected] = false
			if target != 0 { active[target] = true }
			next := link[selected]
			link[selected] = link[target]
			link[target] = next
		}

		mut traversal := [max_n]int{}
		mut count := 0
		mut vertex := link[0]
		for count < n {
			traversal[count] = vertex
			count++
			if vertex == 0 { break }
			vertex = link[vertex]
		}
		if count != n || traversal[count - 1] != 0 { return -1 }

		mut words := [max_output_words]i64{}
		mut prefix_d := i64(0)
		mut objective := i64(0)
		for index in 0 .. n {
			ordered_vertex := traversal[n - 1 - index]
			words[index + 1] = i64(ordered_vertex)
			objective += prefix_d * original_c[ordered_vertex]
			prefix_d += original_d[ordered_vertex]
		}
		words[0] = objective
		output_bytes := 8 * (n + 1)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for word in 0 .. n + 1 { store_i64_le(mut output, 8 * word, words[word]) }
		return i64(output_bytes)
	}
}
