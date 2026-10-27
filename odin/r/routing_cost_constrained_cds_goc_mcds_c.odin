// Clean-room bounded GOC-MCDS-C construction trace.
package routing_cost_constrained_cds_goc_mcds_c

import "core:c"

MAX_N :: 8
MAX_INPUT :: 17

put64 :: proc(out: [^]u8, at: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { out[at+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
routing_cost_constrained_cds_goc_mcds_c :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT || input[0] < 1 || input[0] > 8 do return -1
	n := int(input[0]); if length != c.size_t(1+2*n) do return -1
	full := (u64(1) << n) - 1
	adjacency: [MAX_N]u64
	ids: [MAX_N]i64
	for v := 0; v < n; v += 1 {
		mask := input[1+v]; ids[v] = input[1+n+v]
		if mask < 0 || u64(mask) > full || (u64(mask)&(u64(1)<<v)) != 0 || ids[v] < 1 || ids[v] > 1000 do return -1
		adjacency[v] = u64(mask)
		for u := 0; u < v; u += 1 { if ids[u] == ids[v] do return -1 }
	}
	for u := 0; u < n; u += 1 { for v := 0; v < n; v += 1 { if ((adjacency[u]>>v)&1) != ((adjacency[v]>>u)&1) do return -1 } }
	reached := u64(1)
	for {
		expanded := reached
		for v := 0; v < n; v += 1 { if ((reached>>v)&1) != 0 { expanded |= adjacency[v] } }
		if expanded == reached do break
		reached = expanded
	}
	if reached != full do return -1
	white, independent := full, u64(0)
	for white != 0 {
		black := u64(0)
		for v := 0; v < n; v += 1 {
			if ((white>>v)&1) == 0 do continue
			lower := false
			for u := 0; u < n; u += 1 { if ((white>>u)&1) != 0 && ((adjacency[v]>>u)&1) != 0 && ids[u] < ids[v] { lower = true } }
			if !lower { black |= u64(1)<<v }
		}
		if black == 0 do return -1
		independent |= black; removed := black
		for v := 0; v < n; v += 1 { if ((black>>v)&1) != 0 { removed |= adjacency[v] } }
		white &= ~removed
	}
	order: [MAX_N]int
	for i := 0; i < n; i += 1 { order[i] = i; j := i; for j > 0 && ids[order[j-1]] > ids[order[j]] { order[j-1],order[j] = order[j],order[j-1]; j -= 1 } }
	connectors := u64(0)
	for a := 0; a < n; a += 1 {
		source := order[a]; if ((independent>>source)&1) == 0 do continue
		for b := a+1; b < n; b += 1 {
			target := order[b]; if ((independent>>target)&1) == 0 do continue
			parent: [MAX_N]int; for v := 0; v < n; v += 1 { parent[v] = -2 }
			queue: [MAX_N]int; head,tail := 0,1; parent[source] = -1; queue[0] = source
			for head < tail && parent[target] == -2 {
				current := queue[head]; head += 1
				for oi := 0; oi < n; oi += 1 { next := order[oi]; if ((adjacency[current]>>next)&1) != 0 && parent[next] == -2 { parent[next] = current; queue[tail] = next; tail += 1 } }
			}
			if parent[target] == -2 do return -1
			path: [MAX_N]int; path_length,current := 0,target
			for current != source { path[path_length] = current; path_length += 1; current = parent[current] }
			path[path_length] = source; path_length += 1
			if path_length <= 4 { for i := 1; i+1 < path_length; i += 1 { connectors |= u64(1)<<path[i] } }
		}
	}
	if output == nil || capacity < 16 do return -2
	staged: [16]u8
	put64(&staged[0],0,i64(independent)); put64(&staged[0],8,i64(independent|connectors))
	for i := 0; i < 16; i += 1 { output[i] = staged[i] }
	return 16
}
