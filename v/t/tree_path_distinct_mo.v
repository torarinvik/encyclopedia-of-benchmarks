module tree_path_distinct_mo

const max_n = 32
const max_q = 32
const max_input = 3 * max_n + 2 * max_q
const max_cells = max_n * max_n

struct Query {
mut:
	left      int
	right     int
	id        int
	block     int
	right_key int
}

fn find_root(mut parent []int, item int) int {
	mut node := item
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

fn query_less(a Query, b Query) bool {
	if a.block != b.block { return a.block < b.block }
	if a.right_key != b.right_key { return a.right_key < b.right_key }
	return a.id < b.id
}

fn sift_down(mut values []Query, root_start int, end int) {
	mut root := root_start
	for root * 2 + 1 < end {
		child := root * 2 + 1
		mut largest := root
		if query_less(values[largest], values[child]) { largest = child }
		if child + 1 < end && query_less(values[largest], values[child + 1]) { largest = child + 1 }
		if largest == root { return }
		temporary := values[root]
		values[root] = values[largest]
		values[largest] = temporary
		root = largest
	}
}

fn sort_queries(mut values []Query, count int) {
	mut start := count / 2
	for start > 0 {
		start--
		sift_down(mut values, start, count)
	}
	mut end := count
	for end > 1 {
		end--
		temporary := values[0]
		values[0] = values[end]
		values[end] = temporary
		sift_down(mut values, 0, end)
	}
}

fn lca(a_raw int, b_raw int, parent []int, depth []int) int {
	mut a := a_raw
	mut b := b_raw
	for depth[a] > depth[b] { a = parent[a] }
	for depth[b] > depth[a] { b = parent[b] }
	for a != b { a = parent[a]; b = parent[b] }
	return a
}

fn toggle(vertex int, color_id []int, mut counts []int, mut active []bool, mut distinct int) {
	color := color_id[vertex]
	if active[vertex] {
		active[vertex] = false
		counts[color]--
		if counts[color] == 0 { distinct-- }
	} else {
		active[vertex] = true
		if counts[color] == 0 { distinct++ }
		counts[color]++
	}
}

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'tree_path_distinct_mo']
pub fn tree_path_distinct_mo(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > usize(max_input + 1) { return -1 }
		n_value := input[0]
		q_value := input[1]
		if n_value < 1 || n_value > max_n || q_value < 0 || q_value > max_q { return -1 }
		n := int(n_value)
		q := int(q_value)
		if length != usize(3 * n + 2 * q) { return -1 }

		mut colors := []i64{len: max_n}
		for vertex in 0 .. n { colors[vertex] = input[2 + vertex] }
		mut adjacent := []bool{len: max_cells}
		mut dsu_parent := []int{len: max_n}
		mut dsu_size := []int{len: max_n}
		for vertex in 0 .. n { dsu_parent[vertex] = vertex; dsu_size[vertex] = 1 }
		mut offset := 2 + n
		for _ in 0 .. n - 1 {
			u_value := input[offset]
			v_value := input[offset + 1]
			offset += 2
			if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value { return -1 }
			u := int(u_value)
			v := int(v_value)
			mut root_u := find_root(mut dsu_parent, u)
			mut root_v := find_root(mut dsu_parent, v)
			if root_u == root_v { return -1 }
			if dsu_size[root_u] < dsu_size[root_v] { temporary := root_u; root_u = root_v; root_v = temporary }
			dsu_parent[root_v] = root_u
			dsu_size[root_u] += dsu_size[root_v]
			adjacent[u * max_n + v] = true
			adjacent[v * max_n + u] = true
		}

		mut query_u := []int{len: max_q}
		mut query_v := []int{len: max_q}
		for id in 0 .. q {
			u_value := input[offset]
			v_value := input[offset + 1]
			offset += 2
			if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value { return -1 }
			query_u[id] = int(u_value)
			query_v[id] = int(v_value)
		}

		mut color_id := []int{len: max_n}
		mut first_color := []int{len: max_n}
		mut color_count := 0
		for vertex in 0 .. n {
			mut rank := 0
			for rank < color_count && colors[first_color[rank]] != colors[vertex] { rank++ }
			if rank == color_count { first_color[color_count] = vertex; color_count++ }
			color_id[vertex] = rank
		}

		mut parent := []int{len: max_n, init: -1}
		mut depth := []int{len: max_n}
		mut entry := []int{len: max_n}
		mut leave := []int{len: max_n}
		mut euler := []int{len: 2 * max_n}
		mut event_node := []int{len: 2 * max_n}
		mut event_parent := []int{len: 2 * max_n}
		mut event_exit := []bool{len: 2 * max_n}
		mut top := 1
		mut clock := 0
		event_node[0] = 0
		event_parent[0] = n
		for top > 0 {
			top--
			u := event_node[top]
			previous := event_parent[top]
			if event_exit[top] {
				leave[u] = clock
				euler[clock] = u
				clock++
			} else {
				parent[u] = previous
				entry[u] = clock
				euler[clock] = u
				clock++
				event_node[top] = u
				event_parent[top] = previous
				event_exit[top] = true
				top++
				for v := n - 1; v >= 0; v-- {
					if adjacent[u * max_n + v] && v != previous {
						depth[v] = depth[u] + 1
						event_node[top] = v
						event_parent[top] = u
						event_exit[top] = false
						top++
					}
				}
			}
		}

		mut queries := []Query{len: max_q}
		mut block_size := 1
		for (block_size + 1) * (block_size + 1) <= 2 * n { block_size++ }
		for id in 0 .. q {
			mut u := query_u[id]
			mut v := query_v[id]
			if entry[u] > entry[v] { temporary := u; u = v; v = temporary }
			ancestor := lca(u, v, parent, depth)
			left := if ancestor == u { entry[u] } else { leave[u] }
			right := entry[v]
			block := left / block_size
			right_key := if block % 2 == 0 { right } else { 2 * n - 1 - right }
			queries[id] = Query{left: left, right: right, id: id, block: block, right_key: right_key}
		}
		sort_queries(mut queries, q)

		mut counts := []int{len: max_n}
		mut active := []bool{len: max_n}
		mut answers := []int{len: max_q}
		mut distinct := 0
		mut left := 0
		mut right := -1
		for sorted_id in 0 .. q {
			query := queries[sorted_id]
			for left > query.left { left--; toggle(euler[left], color_id, mut counts, mut active, mut distinct) }
			for right < query.right { right++; toggle(euler[right], color_id, mut counts, mut active, mut distinct) }
			for left < query.left { toggle(euler[left], color_id, mut counts, mut active, mut distinct); left++ }
			for right > query.right { toggle(euler[right], color_id, mut counts, mut active, mut distinct); right-- }
			ancestor := lca(query_u[query.id], query_v[query.id], parent, depth)
			if ancestor != query_u[query.id] && ancestor != query_v[query.id] {
				toggle(ancestor, color_id, mut counts, mut active, mut distinct)
				answers[query.id] = distinct
				toggle(ancestor, color_id, mut counts, mut active, mut distinct)
			} else { answers[query.id] = distinct }
		}

		required := 8 * q
		if output == nil || capacity < usize(required) { return -2 }
		for id in 0 .. q { store_le(mut output, 8 * id, i64(answers[id])) }
		return i64(required)
	}
}
