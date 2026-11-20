// Clean-room bounded Kosaraju plus condensation quotient construction.
@[export: 'scc_condensation_dag']
pub fn scc_condensation_dag(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 58 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 0 || n64 > 8 || m64 < 0 || m64 > 28 { return -1 }
		n := int(n64)
		m := int(m64)
		if length != usize(2 + 2*m) { return -1 }
		mut adjacency := []u16{len: 8, init: 0}
		mut reverse := []u16{len: 8, init: 0}
		for edge in 0 .. m {
			source := input[2+2*edge]
			target := input[3+2*edge]
			if source < 0 || source >= n64 || target < 0 || target >= n64 { return -1 }
			adjacency[int(source)] |= u16(1) << int(target)
			reverse[int(target)] |= u16(1) << int(source)
		}

		mut visited := []bool{len: 8, init: false}
		mut order := []int{len: 8, init: 0}
		mut stack_vertex := []int{len: 8, init: 0}
		mut stack_next := []int{len: 8, init: 0}
		mut order_count := 0
		for start in 0 .. n {
			if visited[start] { continue }
			mut stack_size := 1
			stack_vertex[0] = start
			stack_next[0] = 0
			visited[start] = true
			for stack_size > 0 {
				frame := stack_size - 1
				vertex := stack_vertex[frame]
				mut candidate := stack_next[frame]
				for candidate < n && (adjacency[vertex] & (u16(1) << candidate)) == 0 { candidate++ }
				if candidate < n {
					stack_next[frame] = candidate + 1
					if !visited[candidate] {
						visited[candidate] = true
						stack_vertex[stack_size] = candidate
						stack_next[stack_size] = 0
						stack_size++
					}
				} else {
					order[order_count] = vertex
					order_count++
					stack_size--
				}
			}
		}

		mut raw_component := []int{len: 8, init: -1}
		for vertex in 0 .. n { visited[vertex] = false }
		mut component_count := 0
		for order_count > 0 {
			order_count--
			start := order[order_count]
			if visited[start] { continue }
			mut stack_size := 1
			stack_vertex[0] = start
			visited[start] = true
			raw_component[start] = component_count
			for stack_size > 0 {
				stack_size--
				vertex := stack_vertex[stack_size]
				for next in 0 .. n {
					if (reverse[vertex] & (u16(1) << next)) != 0 && !visited[next] {
						visited[next] = true
						raw_component[next] = component_count
						stack_vertex[stack_size] = next
						stack_size++
					}
				}
			}
			component_count++
		}

		mut minimum := []int{len: 8, init: n}
		mut raw_order := []int{len: 8, init: 0}
		mut canonical := []int{len: 8, init: 0}
		mut labels := []int{len: 8, init: 0}
		mut row_mask := []u8{len: 8, init: 0}
		for component in 0 .. component_count { raw_order[component] = component }
		for vertex in 0 .. n {
			component := raw_component[vertex]
			if vertex < minimum[component] { minimum[component] = vertex }
		}
		for i in 1 .. component_count {
			key := raw_order[i]
			mut j := i
			for j > 0 && minimum[raw_order[j-1]] > minimum[key] {
				raw_order[j] = raw_order[j-1]
				j--
			}
			raw_order[j] = key
		}
		for i in 0 .. component_count { canonical[raw_order[i]] = i }
		for vertex in 0 .. n { labels[vertex] = canonical[raw_component[vertex]] }
		for source in 0 .. n {
			for target in 0 .. n {
				if (adjacency[source] & (u16(1) << target)) == 0 { continue }
				left := labels[source]
				right := labels[target]
				if left != right { row_mask[left] |= u8(1 << right) }
			}
		}

		output_size := 1+n+component_count
		if output == nil || capacity < usize(output_size) { return -2 }
		mut staged := []u8{len: 17, init: 0}
		staged[0] = u8(component_count)
		for vertex in 0 .. n { staged[1+vertex] = u8(labels[vertex]) }
		for component in 0 .. component_count { staged[1+n+component] = row_mask[component] }
		for index in 0 .. output_size { output[index] = staged[index] }
		return i64(output_size)
	}
}
