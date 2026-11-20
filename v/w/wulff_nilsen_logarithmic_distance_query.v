const wn_k = 16
const wn_max_n = 8
const wn_max_m = 28
const wn_max_q = 32
const wn_max_input = 167
const wn_max_nodes = 31
const wn_log_k = 4
const wn_inf = i64(0x3fffffffffffffff)

struct WnNode {
	low int
	high int
	middle int
	gap int
	left int
	right int
}

struct WnState {
mut:
	distance [64]i64
	nearest [128]int
	bunch [64]bool
	trees [248]WnNode
	counts [8]int
}

fn wn_midpoint(low int, high int) int {
	mut chosen := -1
	mut best := 2147483647
	mut candidate := low + 2
	for candidate <= high - 2 {
		mut delta := 2 * candidate - low - high
		if delta < 0 { delta = -delta }
		if delta < best { best = delta; chosen = candidate }
		candidate += 2
	}
	return chosen
}

fn wn_build_tree(mut state WnState, source int, low int, high int) int {
	local := state.counts[source]
	if local >= wn_max_nodes { return -1 }
	state.counts[source]++
	index := source * wn_max_nodes + local
	state.trees[index] = WnNode{low: low, high: high, middle: -1, gap: -1, left: -1, right: -1}
	if high - low <= wn_log_k { return local }

	middle := wn_midpoint(low, high)
	if middle < 0 { return -1 }
	mut selected := low
	near_index := state.nearest[low * wn_max_n + source]
	far_index := state.nearest[(low + 2) * wn_max_n + source]
	mut best_delta := state.distance[source * wn_max_n + far_index] - state.distance[source * wn_max_n + near_index]
	mut level := low + 2
	for level <= middle - 2 {
		near := state.nearest[level * wn_max_n + source]
		far := state.nearest[(level + 2) * wn_max_n + source]
		delta := state.distance[source * wn_max_n + far] - state.distance[source * wn_max_n + near]
		if delta > best_delta { best_delta = delta; selected = level }
		level += 2
	}
	state.trees[index].middle = middle
	state.trees[index].gap = selected
	left_child := wn_build_tree(mut state, source, low, selected)
	right_child := wn_build_tree(mut state, source, middle, high)
	if left_child < 0 || right_child < 0 { return -1 }
	state.trees[index].left = left_child
	state.trees[index].right = right_child
	return local
}

fn wn_dist_k(state &WnState, source0 int, target0 int, start int, mut probes int) i64 {
	mut source := source0
	mut target := target0
	mut level := start
	for level < wn_k {
		pivot := state.nearest[level * wn_max_n + source]
		probes++
		if state.bunch[target * wn_max_n + pivot] {
			return state.distance[source * wn_max_n + pivot] + state.distance[target * wn_max_n + pivot]
		}
		if level + 1 >= wn_k { return -1 }
		source, target = target, source
		level++
	}
	return -1
}

fn wn_put(mut output &u8, position int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[position + byte] = u8((bits >> u64(byte * 8)) & 255) }
	}
}

@[export: 'wulff_nilsen_logarithmic_distance_query']
pub fn wulff_nilsen_logarithmic_distance_query(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 18 || length > wn_max_input { return -1 }
		n0 := input[0]; m0 := input[1]
		if n0 < 1 || n0 > wn_max_n || m0 < 0 || m0 > wn_max_m { return -1 }
		n := int(n0); m := int(m0)
		valid_bits := (u64(1) << u32(n)) - 1
		mut layers := [16]u64{}
		for level in 1 .. wn_k {
			raw := input[1 + level]
			if raw <= 0 || (u64(raw) & ~valid_bits) != 0 { return -1 }
			layers[level] = u64(raw)
			if level > 1 && (layers[level] & ~layers[level - 1]) != 0 { return -1 }
		}
		query_at := 17 + 3 * m
		if query_at >= int(length) || input[query_at] < 0 || input[query_at] > wn_max_q { return -1 }
		q := int(input[query_at])
		if int(length) != query_at + 1 + 2 * q { return -1 }

		mut state := WnState{}
		for i in 0 .. n {
			for j in 0 .. n { state.distance[i * wn_max_n + j] = if i == j { 0 } else { wn_inf } }
		}
		mut previous_u := -1; mut previous_v := -1
		for edge in 0 .. m {
			offset := 17 + 3 * edge
			u0 := input[offset]; v0 := input[offset + 1]; weight := input[offset + 2]
			if u0 < 0 || v0 <= u0 || v0 >= n0 || weight < 1 || weight > 1000 { return -1 }
			u := int(u0); v := int(v0)
			if u < previous_u || (u == previous_u && v <= previous_v) { return -1 }
			previous_u = u; previous_v = v
			state.distance[u * wn_max_n + v] = weight
			state.distance[v * wn_max_n + u] = weight
		}
		for via in 0 .. n {
			for from in 0 .. n {
				for to in 0 .. n {
					candidate := state.distance[from * wn_max_n + via] + state.distance[via * wn_max_n + to]
					if candidate < state.distance[from * wn_max_n + to] { state.distance[from * wn_max_n + to] = candidate }
				}
			}
		}
		for i in 0 .. n { for j in 0 .. n { if state.distance[i * wn_max_n + j] == wn_inf { return -1 } } }

		for vertex in 0 .. n { state.nearest[vertex] = vertex }
		for level in 1 .. wn_k {
			for vertex in 0 .. n {
				mut best := -1
				for candidate in 0 .. n {
					if ((layers[level] >> u32(candidate)) & 1) == 0 { continue }
					if best < 0 { best = candidate }
					else if state.distance[vertex * wn_max_n + candidate] < state.distance[vertex * wn_max_n + best] ||
						(state.distance[vertex * wn_max_n + candidate] == state.distance[vertex * wn_max_n + best] && candidate < best) { best = candidate }
				}
				if best < 0 { return -1 }
				state.nearest[level * wn_max_n + vertex] = best
			}
		}

		for center in 0 .. n {
			for level in 0 .. wn_k {
				current := layers[level]
				if level == 0 { current = valid_bits }
				mut following := u64(0)
				if level + 1 < wn_k { following = layers[level + 1] }
				mut next_distance := wn_inf
				for candidate in 0 .. n {
					if ((following >> u32(candidate)) & 1) != 0 && state.distance[center * wn_max_n + candidate] < next_distance { next_distance = state.distance[center * wn_max_n + candidate] }
				}
				for candidate in 0 .. n {
					in_current := ((current >> u32(candidate)) & 1) != 0
					in_next := ((following >> u32(candidate)) & 1) != 0
					if in_current && !in_next && state.distance[center * wn_max_n + candidate] < next_distance { state.bunch[center * wn_max_n + candidate] = true }
				}
			}
		}
		for source in 0 .. n { if wn_build_tree(mut state, source, 0, wn_k - 1) < 0 { return -1 } }

		mut staged := [65]i64{}
		staged[0] = i64(q)
		for query in 0 .. q {
			offset := query_at + 1 + 2 * query
			source0 := input[offset]; target0 := input[offset + 1]
			if source0 < 0 || source0 >= n0 || target0 < 0 || target0 >= n0 { return -1 }
			source := int(source0); target := int(target0)
			if source == target {
				staged[1 + 2 * query] = 0
				staged[2 + 2 * query] = 0
				continue
			}
			mut node_index := source * wn_max_nodes
			mut probes := 0
			for state.trees[node_index].high - state.trees[node_index].low > wn_log_k {
				node := state.trees[node_index]
				first := state.bunch[target * wn_max_n + state.nearest[node.gap * wn_max_n + source]]
				second := state.bunch[source * wn_max_n + state.nearest[(node.gap + 1) * wn_max_n + target]]
				probes += 2
				child := if !first && !second { node.right } else { node.left }
				node_index = source * wn_max_nodes + child
			}
			estimate := wn_dist_k(state, source, target, state.trees[node_index].low, mut probes)
			if estimate < 0 { return -1 }
			staged[1 + 2 * query] = estimate; staged[2 + 2 * query] = i64(probes)
		}
		words := 1 + 2 * q
		bytes := 8 * words
		if output == nil || capacity < usize(bytes) { return -2 }
		for index in 0 .. words { wn_put(mut output, 8 * index, staged[index]) }
		return i64(bytes)
	}
}
