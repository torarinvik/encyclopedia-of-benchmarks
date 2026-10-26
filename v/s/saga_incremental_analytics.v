// Clean-room bounded SAGA-Bench incremental analytics profile; see package LICENSE.txt.
const max_n = 8
const max_e = 28
const max_input = 97
const inf_value = i64(1_000_000_000)

fn push_once(vertex int, mut queue []int, mut count int, mut seen []bool) {
	if !seen[vertex] {
		seen[vertex] = true
		queue[count] = vertex
		count++
	}
}

fn store_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			*(output + offset + byte) = u8((bits >> (8 * byte)) & 255)
		}
	}
}

@[export: 'saga_incremental_analytics']
pub fn saga_incremental_analytics(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_input { return -1 }
		mode64, n64, base64, added64, source64 := input[0], input[1], input[2], input[3], input[4]
		if mode64 < 1 || mode64 > 6 || n64 < 2 || n64 > max_n || base64 < 0 || added64 < 1 ||
			base64 + added64 > max_e || length != usize(5 + n64 + 3 * (base64 + added64)) { return -1 }
		mode, n, base_edges, edge_count := int(mode64), int(n64), int(base64), int(base64 + added64)
		if mode == 1 || mode == 2 || mode == 5 {
			if source64 < 0 || source64 >= n64 { return -1 }
		} else if source64 != -1 { return -1 }

		mut property := []i64{len: max_n, init: 0}
		for v in 0 .. n {
			value := input[5 + v]
			if mode == 1 && (value < -1 || value >= n64) { return -1 }
			if (mode == 2 || mode == 5) && (value < -1 || value > inf_value) { return -1 }
			if mode == 3 && (value < -1 || value > 1_000_000) { return -1 }
			if (mode == 4 || mode == 6) && (value < -1 || value >= n64) { return -1 }
			property[v] = value
		}
		mut neighbors := []int{len: max_n * max_n, init: 0}
		mut weights := []i64{len: max_n * max_n, init: 0}
		mut degree := []int{len: max_n, init: 0}
		mut edge_seen := []bool{len: max_n * max_n, init: false}
		mut affected := []bool{len: max_n, init: false}
		start := 5 + n
		for edge in 0 .. edge_count {
			pos := start + 3 * edge
			u64, v64, weight := input[pos], input[pos + 1], input[pos + 2]
			if u64 < 0 || v64 <= u64 || v64 >= n64 || weight < 1 || weight > 9 { return -1 }
			u, v := int(u64), int(v64)
			if edge_seen[u * max_n + v] { return -1 }
			edge_seen[u * max_n + v] = true
			edge_seen[v * max_n + u] = true
			neighbors[u * max_n + degree[u]] = v
			weights[u * max_n + degree[u]] = weight
			degree[u]++
			neighbors[v * max_n + degree[v]] = u
			weights[v * max_n + degree[v]] = weight
			degree[v]++
			if edge >= base_edges { affected[u] = true; affected[v] = true }
		}
		if mode == 3 {
			for v in 0 .. n { if degree[v] == 0 { return -1 } }
		}
		output_bytes := 8 * n
		if output == nil || capacity < usize(output_bytes) { return -2 }
		if mode == 1 && property[int(source64)] == -1 { property[int(source64)] = 0 }
		if mode == 2 || mode == 5 {
			for v in 0 .. n {
				if property[v] == -1 {
					if v == int(source64) { property[v] = if mode == 2 { i64(0) } else { inf_value } }
					else { property[v] = if mode == 2 { inf_value } else { i64(0) } }
				}
			}
		}
		if mode == 4 || mode == 6 {
			for v in 0 .. n { if property[v] == -1 { property[v] = i64(v) } }
		}

		if mode == 3 {
			damping := f32(0.85)
			base := (f32(1.0) - damping) / f32(n)
			mut rank := []f32{len: max_n, init: 0}
			mut contribution := []f32{len: max_n, init: 0}
			for v in 0 .. n {
				rank[v] = if property[v] == -1 { f32(1.0) / f32(n) } else { f32(property[v]) / f32(1_000_000) }
				contribution[v] = rank[v] / f32(degree[v])
			}
			mut queue := []int{len: max_n, init: 0}
			mut count := 0
			mut seen := []bool{len: max_n, init: false}
			for v in 0 .. n {
				if affected[v] {
					mut incoming := f32(0.0)
					for j in 0 .. degree[v] { incoming += contribution[neighbors[v * max_n + j]] }
					old := rank[v]
					rank[v] = base + damping * incoming
					mut difference := rank[v] - old
					if difference < 0 { difference = -difference }
					if difference > f32(1.0e-7) {
						for j in 0 .. degree[v] { push_once(neighbors[v * max_n + j], mut queue, mut count, mut seen) }
					}
				}
			}
			mut rounds := 0
			for count != 0 {
				rounds++
				if rounds > 256 { return -1 }
				for v in 0 .. n { contribution[v] = rank[v] / f32(degree[v]) }
				current := queue.clone()
				current_count := count
				count = 0
				seen = []bool{len: max_n, init: false}
				for q in 0 .. current_count {
					v := current[q]
					mut incoming := f32(0.0)
					for j in 0 .. degree[v] { incoming += contribution[neighbors[v * max_n + j]] }
					old := rank[v]
					rank[v] = base + damping * incoming
					mut difference := rank[v] - old
					if difference < 0 { difference = -difference }
					if difference > f32(1.0e-7) {
						for j in 0 .. degree[v] { push_once(neighbors[v * max_n + j], mut queue, mut count, mut seen) }
					}
				}
			}
			for v in 0 .. n { property[v] = i64(rank[v] * f32(1_000_000) + f32(0.5)) }
		} else {
			mut active := []int{len: max_n, init: 0}
			mut active_count := 0
			for v in 0 .. n { if affected[v] { active[active_count] = v; active_count++ } }
			mut first := true
			mut rounds := 0
			for active_count != 0 {
				rounds++
				if rounds > 256 { return -1 }
				mut next := []int{len: max_n, init: 0}
				mut next_count := 0
				mut next_seen := []bool{len: max_n, init: false}
				for a in 0 .. active_count {
					v := active[a]
					old := property[v]
					mut candidate := i64(0)
					if mode == 1 || mode == 2 || mode == 4 { candidate = inf_value }
					if mode == 1 {
						for j in 0 .. degree[v] { p := property[neighbors[v * max_n + j]]; if p != -1 && p + 1 < candidate { candidate = p + 1 } }
					} else if mode == 2 {
						for j in 0 .. degree[v] { p := property[neighbors[v * max_n + j]] + weights[v * max_n + j]; if p < candidate { candidate = p } }
					} else if mode == 4 {
						candidate = old
						for j in 0 .. degree[v] { candidate = min(candidate, property[neighbors[v * max_n + j]]) }
					} else if mode == 5 {
						for j in 0 .. degree[v] { candidate = max(candidate, min(property[neighbors[v * max_n + j]], weights[v * max_n + j])) }
					} else {
						candidate = old
						for j in 0 .. degree[v] { candidate = max(candidate, property[neighbors[v * max_n + j]]) }
					}
					mut changed := false
					if mode == 1 { changed = candidate != inf_value && (old == -1 || candidate < old) }
					else if mode == 2 { changed = candidate < old && candidate != inf_value }
					else if mode == 4 { changed = candidate < old || (first && old == i64(v)) }
					else if mode == 5 { changed = candidate > old }
					else { changed = candidate > old || (first && old == i64(v)) }
					if changed {
                        property[v] = candidate
                        if mode == 1 {
                            for j in 0 .. degree[v] {
                                u := neighbors[v * max_n + j]
                                update := property[v] + 1
                                if property[u] == -1 || update < property[u] {
                                    property[u] = update
                                    push_once(u, mut next, mut next_count, mut next_seen)
                                }
                            }
                        } else {
                            for j in 0 .. degree[v] { push_once(neighbors[v * max_n + j], mut next, mut next_count, mut next_seen) }
                        }
					}
				}
				active, active_count, first = next, next_count, false
			}
		}
		for v in 0 .. n { store_i64_le(output, 8 * v, property[v]) }
		return i64(output_bytes)
	}
}
