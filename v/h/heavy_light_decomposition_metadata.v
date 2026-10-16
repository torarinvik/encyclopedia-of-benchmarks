module heavy_light_decomposition_metadata

import core:c

const max_vertices = 128

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'heavy_light_decomposition_metadata']
pub fn heavy_light_decomposition_metadata(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	unsafe {
		nv, mv := input[0], input[1]
		if nv < 1 || nv > max_vertices || mv != nv - 1 || length != usize(2 + 2 * mv) { return -1 }
		n, m := int(nv), int(mv)
		mut adjacency := [max_vertices * max_vertices]int{}
		mut degree := [max_vertices]int{}
		for edge in 0 .. m {
			uv, vv := input[2 + 2 * edge], input[3 + 2 * edge]
			if uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv { return -1 }
			u, v := int(uv), int(vv)
			for i in 0 .. degree[u] {
				if adjacency[u * max_vertices + i] == v { return -1 }
			}
			adjacency[u * max_vertices + degree[u]] = v
			degree[u]++
			adjacency[v * max_vertices + degree[v]] = u
			degree[v]++
		}

		mut parent := [max_vertices]int{}
		mut order := [max_vertices]int{}
		mut stack := [max_vertices]int{}
		for v in 0 .. n { parent[v] = -2 }
		parent[0] = -1
		mut top := 1
		mut order_count := 0
		stack[0] = 0
		for top > 0 {
			top--
			vertex := stack[top]
			order[order_count] = vertex
			order_count++
			for i := degree[vertex] - 1; i >= 0; i-- {
				child := adjacency[vertex * max_vertices + i]
				if parent[child] == -2 {
					parent[child] = vertex
					stack[top] = child
					top++
				}
			}
		}
		if order_count != n { return -1 }

		mut subtree_size := [max_vertices]int{}
		mut big_child := [max_vertices]int{}
		for v in 0 .. n { big_child[v] = -1 }
		for index := n - 1; index >= 0; index-- {
			vertex := order[index]
			mut best_size := 0
			subtree_size[vertex] = 1
			for i in 0 .. degree[vertex] {
				child := adjacency[vertex * max_vertices + i]
				if parent[child] != vertex { continue }
				subtree_size[vertex] += subtree_size[child]
				if subtree_size[child] > best_size {
					best_size = subtree_size[child]
					big_child[vertex] = child
				}
			}
		}

		mut position := [max_vertices]int{}
		mut head := [max_vertices]int{}
		mut stack_head := [max_vertices]int{}
		top = 1
		mut next_position := 0
		stack[0] = 0
		stack_head[0] = 0
		for top > 0 {
			top--
			vertex, chain_head := stack[top], stack_head[top]
			position[vertex] = next_position
			next_position++
			head[vertex] = chain_head
			for i := degree[vertex] - 1; i >= 0; i-- {
				child := adjacency[vertex * max_vertices + i]
				if parent[child] == vertex && child != big_child[vertex] {
					stack[top] = child
					stack_head[top] = child
					top++
				}
			}
			if big_child[vertex] >= 0 {
				stack[top] = big_child[vertex]
				stack_head[top] = chain_head
				top++
			}
		}

		required := (1 + 3 * n) * 8
		if capacity < required || (required != 0 && output == nil) { return -2 }
		mut cursor := 0
		put_i64(mut output, cursor * 8, nv)
		cursor++
		for vertex in 0 .. n {
			put_i64(mut output, cursor * 8, i64(position[vertex]))
			cursor++
			put_i64(mut output, cursor * 8, i64(head[vertex]))
			cursor++
			put_i64(mut output, cursor * 8, i64(big_child[vertex]))
			cursor++
		}
		return i64(required)
	}
}
