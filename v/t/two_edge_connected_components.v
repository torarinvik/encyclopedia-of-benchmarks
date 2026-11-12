module two_edge_connected_components

const max_n = 6
const max_m = 10
const max_adj = 20
const max_output_values = 13
const max_output_bytes = 104
const max_input_length = 22

struct GraphContext {
	n int
	m int
	degree [6]int
	adjacent_vertex [120]int
	adjacent_edge [120]int
	discovery [6]int
	low [6]int
	is_bridge [10]bool
	clock int
	component [6]int
	block_vertices [36]int
	block_size [6]int
	block_count int
}

fn find_bridges(mut context &GraphContext, vertex int, parent_edge int) {
	context.discovery[vertex] = context.clock
	context.low[vertex] = context.clock
	context.clock++
	for slot in 0 .. context.degree[vertex] {
		index := vertex * max_adj + slot
		neighbor := context.adjacent_vertex[index]
		edge := context.adjacent_edge[index]
		if edge == parent_edge { continue }
		if context.discovery[neighbor] < 0 {
			find_bridges(mut context, neighbor, edge)
			if context.low[neighbor] < context.low[vertex] { context.low[vertex] = context.low[neighbor] }
			if context.low[neighbor] > context.discovery[vertex] { context.is_bridge[edge] = true }
		} else if context.discovery[neighbor] < context.low[vertex] {
			context.low[vertex] = context.discovery[neighbor]
		}
	}
}

fn assign_components(mut context &GraphContext) {
	mut queue := [max_n]int{}
	for root in 0 .. context.n {
		if context.component[root] >= 0 { continue }
		block := context.block_count
		context.block_count++
		mut head := 0
		mut tail := 0
		context.component[root] = block
		queue[tail] = root
		tail++
		for head < tail {
			vertex := queue[head]
			head++
			for slot in 0 .. context.degree[vertex] {
				index := vertex * max_adj + slot
				neighbor := context.adjacent_vertex[index]
				edge := context.adjacent_edge[index]
				if context.is_bridge[edge] || context.component[neighbor] >= 0 { continue }
				context.component[neighbor] = block
				queue[tail] = neighbor
				tail++
			}
		}
		for vertex in 0 .. context.n {
			if context.component[vertex] == block {
				context.block_vertices[block * max_n + context.block_size[block]] = vertex
				context.block_size[block]++
			}
		}
	}
}

fn block_less(context &GraphContext, left int, right int) bool {
	common := context.block_size[left]
	if context.block_size[right] < common { common = context.block_size[right] }
	for i in 0 .. common {
		a := context.block_vertices[left * max_n + i]
		b := context.block_vertices[right * max_n + i]
		if a != b { return a < b }
	}
	return context.block_size[left] < context.block_size[right]
}

fn store_u64_le(mut output &u8, offset int, value u64) {
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((value >> u64(byte * 8)) & 255) } }
}

@[export: 'two_edge_connected_components']
pub fn two_edge_connected_components(input &i64, length usize, mut output &u8,
	output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		n_value, m_value := input[0], input[1]
		if n_value < 1 || n_value > max_n || m_value < 0 || m_value > max_m { return -1 }
		n, m := int(n_value), int(m_value)
		if length != usize(2 + 2 * m) { return -1 }

		mut context := GraphContext{}
		context.n, context.m = n, m
		for vertex in 0 .. n {
			context.discovery[vertex] = -1
			context.component[vertex] = -1
		}
		for edge in 0 .. m {
			left_value, right_value := input[2 + 2 * edge], input[3 + 2 * edge]
			if left_value < 0 || left_value >= n_value || right_value < 0 || right_value >= n_value { return -1 }
			left, right := int(left_value), int(right_value)
			left_slot := context.degree[left]
			context.degree[left]++
			right_slot := context.degree[right]
			context.degree[right]++
			context.adjacent_vertex[left * max_adj + left_slot] = right
			context.adjacent_edge[left * max_adj + left_slot] = edge
			context.adjacent_vertex[right * max_adj + right_slot] = left
			context.adjacent_edge[right * max_adj + right_slot] = edge
		}
		for root in 0 .. n {
			if context.discovery[root] < 0 { find_bridges(mut context, root, max_m) }
		}
		assign_components(mut context)

		mut order := [max_n]int{}
		for i in 0 .. context.block_count {
			mut position := i
			order[i] = i
			for position > 0 && block_less(context, order[position], order[position - 1]) {
				temporary := order[position]
				order[position] = order[position - 1]
				order[position - 1] = temporary
				position--
			}
		}
		mut staged := [max_output_bytes]u8{}
		mut packed_count := 0
		store_u64_le(mut staged[0], packed_count * 8, u64(context.block_count))
		packed_count++
		for i in 0 .. context.block_count {
			block := order[i]
			store_u64_le(mut staged[0], packed_count * 8, u64(context.block_size[block]))
			packed_count++
			for j in 0 .. context.block_size[block] {
				store_u64_le(mut staged[0], packed_count * 8, u64(context.block_vertices[block * max_n + j]))
				packed_count++
			}
		}
		bytes := 8 * packed_count
		if output == nil || output_capacity < usize(bytes) { return -2 }
		for byte in 0 .. bytes { output[byte] = staged[byte] }
		return i64(bytes)
	}
}
