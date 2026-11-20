package wulff_nilsen_logarithmic_distance_query

import "core:c"

K :: 16
MAX_N :: 8
MAX_M :: 28
MAX_Q :: 32
MAX_INPUT :: 167
MAX_NODES :: 31
LOG_K :: 4
INF :: i64(0x3fffffffffffffff)

Interval_Node :: struct {
	low, high, middle, gap, left, right: int,
}

Query_State :: struct {
	distance: [MAX_N][MAX_N]i64,
	nearest: [K][MAX_N]int,
	bunch: [MAX_N][MAX_N]bool,
	trees: [MAX_N][MAX_NODES]Interval_Node,
	counts: [MAX_N]int,
}

midpoint :: proc(low, high: int) -> int {
	chosen := -1
	best := 2147483647
	for candidate := low + 2; candidate <= high - 2; candidate += 2 {
		delta := 2*candidate - low - high
		if delta < 0 { delta = -delta }
		if delta < best { best = delta; chosen = candidate }
	}
	return chosen
}

build_tree :: proc(state: ^Query_State, source, low, high: int) -> int {
	index := state.counts[source]
	if index >= MAX_NODES { return -1 }
	state.counts[source] += 1
	state.trees[source][index] = Interval_Node{low = low, high = high, middle = -1, gap = -1, left = -1, right = -1}
	if high - low <= LOG_K { return index }

	middle := midpoint(low, high)
	if middle < 0 { return -1 }
	selected := low
	best_delta := state.distance[source][state.nearest[low+2][source]] - state.distance[source][state.nearest[low][source]]
	for level := low + 2; level <= middle - 2; level += 2 {
		delta := state.distance[source][state.nearest[level+2][source]] - state.distance[source][state.nearest[level][source]]
		if delta > best_delta { best_delta = delta; selected = level }
	}
	state.trees[source][index].middle = middle
	state.trees[source][index].gap = selected
	left_child := build_tree(state, source, low, selected)
	right_child := build_tree(state, source, middle, high)
	if left_child < 0 || right_child < 0 { return -1 }
	state.trees[source][index].left = left_child
	state.trees[source][index].right = right_child
	return index
}

dist_k :: proc(state: ^Query_State, source_value, target_value, start: int,
		probes: ^int) -> i64 {
	source := source_value
	target := target_value
	level := start
	for level < K {
		pivot := state.nearest[level][source]
		probes^ += 1
		if state.bunch[target][pivot] {
			return state.distance[source][pivot] + state.distance[target][pivot]
		}
		if level + 1 >= K { return -1 }
		source, target = target, source
		level += 1
	}
	return -1
}

put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits >> (8*byte)) & 255) }
}

@(export)
wulff_nilsen_logarithmic_distance_query :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 18 || length > MAX_INPUT { return -1 }
	n0, m0 := input[0], input[1]
	if n0 < 1 || n0 > MAX_N || m0 < 0 || m0 > MAX_M { return -1 }
	n, m := int(n0), int(m0)
	valid_bits := (u64(1) << n) - 1
	var layers: [K]u64
	for level := 1; level < K; level += 1 {
		raw := input[1+level]
		if raw <= 0 || (u64(raw) & ~valid_bits) != 0 { return -1 }
		layers[level] = u64(raw)
		if level > 1 && (layers[level] & ~layers[level-1]) != 0 { return -1 }
	}
	query_at := 17 + 3*m
	if query_at >= int(length) || input[query_at] < 0 || input[query_at] > MAX_Q { return -1 }
	q := int(input[query_at])
	if int(length) != query_at + 1 + 2*q { return -1 }

	var state: Query_State
	for i := 0; i < n; i += 1 {
		for j := 0; j < n; j += 1 { state.distance[i][j] = INF }
		state.distance[i][i] = 0
	}
	previous_u, previous_v := -1, -1
	for edge := 0; edge < m; edge += 1 {
		offset := 17 + 3*edge
		u0, v0, weight := input[offset], input[offset+1], input[offset+2]
		if u0 < 0 || v0 <= u0 || v0 >= n0 || weight < 1 || weight > 1000 { return -1 }
		u, v := int(u0), int(v0)
		if u < previous_u || (u == previous_u && v <= previous_v) { return -1 }
		previous_u, previous_v = u, v
		state.distance[u][v] = weight; state.distance[v][u] = weight
	}
	for via := 0; via < n; via += 1 {
		for from := 0; from < n; from += 1 {
			for to := 0; to < n; to += 1 {
				candidate := state.distance[from][via] + state.distance[via][to]
				if candidate < state.distance[from][to] { state.distance[from][to] = candidate }
			}
		}
	}
	for i := 0; i < n; i += 1 { for j := 0; j < n; j += 1 { if state.distance[i][j] == INF { return -1 } } }

	for vertex := 0; vertex < n; vertex += 1 { state.nearest[0][vertex] = vertex }
	for level := 1; level < K; level += 1 {
		for vertex := 0; vertex < n; vertex += 1 {
			best := -1
			for candidate := 0; candidate < n; candidate += 1 {
				if ((layers[level] >> candidate) & 1) == 0 { continue }
				if best < 0 { best = candidate }
				else if state.distance[vertex][candidate] < state.distance[vertex][best] ||
					(state.distance[vertex][candidate] == state.distance[vertex][best] && candidate < best) { best = candidate }
			}
			if best < 0 { return -1 }
			state.nearest[level][vertex] = best
		}
	}

	for center := 0; center < n; center += 1 {
		for level := 0; level < K; level += 1 {
			current := layers[level]
			if level == 0 { current = valid_bits }
			following := u64(0)
			if level + 1 < K { following = layers[level+1] }
			next_distance := INF
			for candidate := 0; candidate < n; candidate += 1 {
				if ((following >> candidate) & 1) != 0 && state.distance[center][candidate] < next_distance { next_distance = state.distance[center][candidate] }
			}
			for candidate := 0; candidate < n; candidate += 1 {
				in_current := ((current >> candidate) & 1) != 0
				in_next := ((following >> candidate) & 1) != 0
				if in_current && !in_next && state.distance[center][candidate] < next_distance { state.bunch[center][candidate] = true }
			}
		}
	}
	for source := 0; source < n; source += 1 { if build_tree(&state, source, 0, K-1) < 0 { return -1 } }

	var staged: [1+2*MAX_Q]i64
	staged[0] = i64(q)
	for query := 0; query < q; query += 1 {
		offset := query_at + 1 + 2*query
		source0, target0 := input[offset], input[offset+1]
		if source0 < 0 || source0 >= n0 || target0 < 0 || target0 >= n0 { return -1 }
		source, target := int(source0), int(target0)
		if source == target {
			staged[1+2*query] = 0
			staged[2+2*query] = 0
			continue
		}
		node_index := 0
		probes := 0
		for state.trees[source][node_index].high - state.trees[source][node_index].low > LOG_K {
			node := state.trees[source][node_index]
			first := state.bunch[target][state.nearest[node.gap][source]]
			second := state.bunch[source][state.nearest[node.gap+1][target]]
		probes += 2
			if !first && !second { node_index = node.right } else { node_index = node.left }
		}
		estimate := dist_k(&state, source, target, state.trees[source][node_index].low, &probes)
		if estimate < 0 { return -1 }
		staged[1+2*query] = estimate; staged[2+2*query] = i64(probes)
	}
	words := 1 + 2*q
	bytes := 8*words
	if output == nil || capacity < c.size_t(bytes) { return -2 }
	for index := 0; index < words; index += 1 { put_i64_le(output, 8*index, staged[index]) }
	return i64(bytes)
}
