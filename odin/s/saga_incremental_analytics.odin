package saga_incremental_analytics

import "core:c"

// Clean-room bounded SAGA-Bench incremental analytics profile; see package LICENSE.txt.
MAX_N :: 8
MAX_E :: 28
MAX_INPUT :: 5 + MAX_N + 3 * MAX_E
INF_VALUE: i64 = 1_000_000_000

push_once :: proc(vertex: int, queue: ^[MAX_N]int, count: ^int, seen: ^[MAX_N]bool) {
	if !seen[vertex] {
		seen[vertex] = true
		queue[count^] = vertex
		count^ += 1
	}
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8((bits >> (8 * byte)) & 255)
	}
}

@(export)
saga_incremental_analytics :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_INPUT do return -1
	mode64, n64, base64, added64, source64 := input[0], input[1], input[2], input[3], input[4]
	if mode64 < 1 || mode64 > 6 || n64 < 2 || n64 > MAX_N || base64 < 0 || added64 < 1 ||
		base64+added64 > MAX_E || length != c.size_t(5+n64+3*(base64+added64)) do return -1
	mode, n, base_edges, edge_count := int(mode64), int(n64), int(base64), int(base64+added64)
	if mode == 1 || mode == 2 || mode == 5 {
		if source64 < 0 || source64 >= n64 do return -1
	} else if source64 != -1 do return -1

	property: [MAX_N]i64 = {}
	for v := 0; v < n; v += 1 {
		value := input[5+v]
		if mode == 1 && (value < -1 || value >= n64) do return -1
		if (mode == 2 || mode == 5) && (value < -1 || value > INF_VALUE) do return -1
		if mode == 3 && (value < -1 || value > 1_000_000) do return -1
		if (mode == 4 || mode == 6) && (value < -1 || value >= n64) do return -1
		property[v] = value
	}
	neighbors: [MAX_N][MAX_N]int = {}
	weights: [MAX_N][MAX_N]i64 = {}
	degree: [MAX_N]int = {}
	edge_seen: [MAX_N][MAX_N]bool = {}
	affected: [MAX_N]bool = {}
	start := 5 + n
	for edge := 0; edge < edge_count; edge += 1 {
		pos := start + 3*edge
		u64, v64, weight := input[pos], input[pos+1], input[pos+2]
		if u64 < 0 || v64 <= u64 || v64 >= n64 || weight < 1 || weight > 9 do return -1
		u, v := int(u64), int(v64)
		if edge_seen[u][v] do return -1
		edge_seen[u][v], edge_seen[v][u] = true, true
		neighbors[u][degree[u]], weights[u][degree[u]] = v, weight
		degree[u] += 1
		neighbors[v][degree[v]], weights[v][degree[v]] = u, weight
		degree[v] += 1
		if edge >= base_edges { affected[u], affected[v] = true, true }
	}
	if mode == 3 {
		for v := 0; v < n; v += 1 { if degree[v] == 0 do return -1 }
	}
	output_bytes := 8 * n
	if output == nil || capacity < c.size_t(output_bytes) do return -2

	if mode == 1 && property[int(source64)] == -1 do property[int(source64)] = 0
	if mode == 2 || mode == 5 {
		for v := 0; v < n; v += 1 {
			if property[v] == -1 {
				if v == int(source64) {
					if mode == 2 { property[v] = 0 } else { property[v] = INF_VALUE }
				} else {
					if mode == 2 { property[v] = INF_VALUE } else { property[v] = 0 }
				}
			}
		}
	}
	if mode == 4 || mode == 6 {
		for v := 0; v < n; v += 1 { if property[v] == -1 do property[v] = i64(v) }
	}

	if mode == 3 {
		damping := f32(0.85)
		base := (f32(1)-damping) / f32(n)
		rank: [MAX_N]f32 = {}
		contribution: [MAX_N]f32 = {}
		for v := 0; v < n; v += 1 {
			if property[v] == -1 { rank[v] = f32(1)/f32(n) }
			else { rank[v] = f32(property[v])/f32(1_000_000) }
			contribution[v] = rank[v] / f32(degree[v])
		}
		queue: [MAX_N]int = {}
		count := 0
		seen: [MAX_N]bool = {}
		for v := 0; v < n; v += 1 {
			if affected[v] {
				incoming := f32(0)
				for j := 0; j < degree[v]; j += 1 { incoming += contribution[neighbors[v][j]] }
				old := rank[v]
				rank[v] = base + damping*incoming
				difference := rank[v]-old
				if difference < 0 { difference = -difference }
				if difference > f32(1e-7) {
					for j := 0; j < degree[v]; j += 1 { push_once(neighbors[v][j], &queue, &count, &seen) }
				}
			}
		}
		rounds := 0
		for count != 0 {
			rounds += 1
			if rounds > 256 do return -1
			for v := 0; v < n; v += 1 { contribution[v] = rank[v] / f32(degree[v]) }
			current := queue
			current_count := count
			count = 0
			seen = {}
			for q := 0; q < current_count; q += 1 {
				v := current[q]
				incoming := f32(0)
				for j := 0; j < degree[v]; j += 1 { incoming += contribution[neighbors[v][j]] }
				old := rank[v]
				rank[v] = base + damping*incoming
				difference := rank[v]-old
				if difference < 0 { difference = -difference }
				if difference > f32(1e-7) {
					for j := 0; j < degree[v]; j += 1 { push_once(neighbors[v][j], &queue, &count, &seen) }
				}
			}
		}
		for v := 0; v < n; v += 1 { property[v] = i64(rank[v]*f32(1_000_000)+f32(0.5)) }
	} else {
		active: [MAX_N]int = {}
		active_count := 0
		for v := 0; v < n; v += 1 { if affected[v] { active[active_count] = v; active_count += 1 } }
		first := true
		rounds := 0
		for active_count != 0 {
			rounds += 1
			if rounds > 256 do return -1
			next: [MAX_N]int = {}
			next_count := 0
			seen: [MAX_N]bool = {}
			for a := 0; a < active_count; a += 1 {
				v := active[a]
				old := property[v]
				candidate: i64 = 0
				if mode == 1 || mode == 2 || mode == 4 { candidate = INF_VALUE }
				if mode == 1 {
					for j := 0; j < degree[v]; j += 1 {
						p := property[neighbors[v][j]]
						if p != -1 && p+1 < candidate { candidate = p+1 }
					}
				} else if mode == 2 {
					for j := 0; j < degree[v]; j += 1 { p := property[neighbors[v][j]]+weights[v][j]; if p < candidate { candidate = p } }
				} else if mode == 4 {
					candidate = old
					for j := 0; j < degree[v]; j += 1 { candidate = min(candidate, property[neighbors[v][j]]) }
				} else if mode == 5 {
					for j := 0; j < degree[v]; j += 1 { candidate = max(candidate, min(property[neighbors[v][j]], weights[v][j])) }
				} else {
					candidate = old
					for j := 0; j < degree[v]; j += 1 { candidate = max(candidate, property[neighbors[v][j]]) }
				}
				changed := false
				if mode == 1 { changed = candidate != INF_VALUE && (old == -1 || candidate < old) }
				else if mode == 2 { changed = candidate < old && candidate != INF_VALUE }
				else if mode == 4 { changed = candidate < old || (first && old == i64(v)) }
				else if mode == 5 { changed = candidate > old }
				else { changed = candidate > old || (first && old == i64(v)) }
				if changed {
                    property[v] = candidate
                    if mode == 1 {
                        for j := 0; j < degree[v]; j += 1 {
                            u := neighbors[v][j]
                            update := property[v] + 1
                            if property[u] == -1 || update < property[u] {
                                property[u] = update
                                push_once(u, &next, &next_count, &seen)
                            }
                        }
                    } else {
                        for j := 0; j < degree[v]; j += 1 { push_once(neighbors[v][j], &next, &next_count, &seen) }
                    }
				}
			}
			active, active_count, first = next, next_count, false
		}
	}
	for v := 0; v < n; v += 1 { store_i64_le(output, 8*v, property[v]) }
	return i64(output_bytes)
}
