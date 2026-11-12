package games_on_arbitrary_graphs

import "core:c"

MAX_V :: 16
MAX_E :: 32
MAX_INPUT :: 66
MAX_OUTPUT :: 17

@(export)
games_on_arbitrary_graphs :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	nv, me := input[0], input[1]
	if nv < 0 || nv > MAX_V || me < 0 || me > MAX_E do return -1
	n, m := int(nv), int(me)
	if int(length) != 2 + 2 * m do return -1

	var outmask: [MAX_V]u16
	var head: [MAX_V]int
	var edge_source, edge_next: [MAX_E]int
	var remaining, status, queue: [MAX_V]int
	var staged: [MAX_OUTPUT]u8
	for v := 0; v < n; v += 1 { head[v] = -1 }
	unique_edges := 0
	for i := 0; i < m; i += 1 {
		sv, tv := input[2 + 2 * i], input[3 + 2 * i]
		if sv < 0 || sv >= nv || tv < 0 || tv >= nv do return -1
		s, t := int(sv), int(tv)
		bit := u16(1) << u16(t)
		if (outmask[s] & bit) == 0 {
			outmask[s] |= bit
			edge_source[unique_edges] = s
			edge_next[unique_edges] = head[t]
			head[t] = unique_edges
			unique_edges += 1
			remaining[s] += 1
		}
	}

	first, count := 0, 0
	for v := 0; v < n; v += 1 {
		if remaining[v] == 0 { status[v] = 2; queue[count] = v; count += 1 }
	}
	for first < count {
		resolved := queue[first]
		first += 1
		edge := head[resolved]
		for edge != -1 {
			predecessor := edge_source[edge]
			if status[predecessor] == 0 {
				if status[resolved] == 2 {
					status[predecessor] = 1
					queue[count] = predecessor
					count += 1
				} else {
					remaining[predecessor] -= 1
					if remaining[predecessor] == 0 {
						status[predecessor] = 2
						queue[count] = predecessor
						count += 1
					}
				}
			}
			edge = edge_next[edge]
		}
	}
	staged[0] = u8(n)
	for v := 0; v < n; v += 1 { staged[v + 1] = u8(status[v]) }
	needed := n + 1
	if output == nil || int(capacity) < needed do return -2
	for i := 0; i < needed; i += 1 { output[i] = staged[i] }
	return i64(needed)
}
