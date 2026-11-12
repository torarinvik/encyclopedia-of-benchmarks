package all_shortest_paths_unweighted

import "core:c"

MAX_V :: 16
MAX_E :: 64
MAX_INPUT :: 133
MAX_PATHS :: 162
MAX_OUTPUT :: 1296

Search :: struct {
	n: int,
	target: int,
	predecessor: [MAX_V][MAX_V]bool,
	useful: [MAX_V]bool,
	path: [MAX_V]u8,
	output: [MAX_OUTPUT]u8,
	used: int,
	count: int,
	overflow: bool,
}

enumerate :: proc "contextless" (s: ^Search, u: int, depth: int) {
	if s.overflow do return
	s.path[depth] = u8(u)
	if u == s.target {
		if s.count >= MAX_PATHS || s.used + depth + 2 > MAX_OUTPUT do { s.overflow = true; return }
		for i in 0..=depth { s.output[s.used] = s.path[i]; s.used += 1 }
		s.output[s.used] = 0xff; s.used += 1; s.count += 1
		return
	}
	for v in 0..<s.n {
		if s.overflow do break
		if s.useful[v] && s.predecessor[v][u] do enumerate(s, v, depth + 1)
	}
}

@(export)
all_shortest_paths_unweighted :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 4 || length > MAX_INPUT do return -1
	if values[0] < 1 || values[0] > MAX_V || values[1] < 0 || values[1] > MAX_E do return -1
	n, m := int(values[0]), int(values[1])
	if values[2] < 0 || values[2] >= i64(n) || values[3] < 0 || values[3] >= i64(n) || int(length) != 4 + 2*m do return -1
	source, target := int(values[2]), int(values[3])
	adjacent: [MAX_V][MAX_V]bool = {}
	for e in 0..<m {
		raw_u, raw_v := values[4+2*e], values[5+2*e]
		if raw_u < 0 || raw_u >= i64(n) || raw_v < 0 || raw_v >= i64(n) || raw_u == raw_v do return -1
		u, v := int(raw_u), int(raw_v)
		if adjacent[u][v] do return -1
		adjacent[u][v], adjacent[v][u] = true, true
	}
	var distance: [MAX_V]int
	var queue: [MAX_V]int
	predecessor: [MAX_V][MAX_V]bool = {}
	for v in 0..<n { distance[v] = -1 }
	head, tail := 0, 0
	distance[source] = 0; queue[tail] = source; tail += 1
	for head < tail {
		u := queue[head]; head += 1
		for v in 0..<n {
			if !adjacent[u][v] do continue
			if distance[v] < 0 { distance[v] = distance[u] + 1; queue[tail] = v; tail += 1 }
			if distance[v] == distance[u] + 1 { predecessor[v][u] = true }
		}
	}
	useful: [MAX_V]bool = {}
	if distance[target] >= 0 {
		var stack: [MAX_V]int
		size := 0
		useful[target] = true; stack[size] = target; size += 1
		for size > 0 {
			size -= 1; v := stack[size]
			for u in 0..<n {
				if predecessor[v][u] && !useful[u] { useful[u] = true; stack[size] = u; size += 1 }
			}
		}
	}
	s := Search{n = n, target = target, predecessor = predecessor, useful = useful}
	if distance[target] >= 0 do enumerate(&s, source, 0)
	if s.overflow do return -2
	if output == nil || capacity < c.size_t(s.used) do return -2
	for i in 0..<s.used { output[i] = s.output[i] }
	return i64(s.count)
}
