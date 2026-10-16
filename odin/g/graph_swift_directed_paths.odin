package graph_swift_directed_paths

import "core:c"

N :: 32
M :: 256
Q :: 64

put_i64 :: proc "contextless" (output: [^]u8, word: c.size_t, value: i64) {
	bits := u64(value)
	for byte: c.size_t = 0; byte < 8; byte += 1 { output[word*8+byte] = u8(bits >> (byte*8)) }
}

@(export)
graph_swift_directed_paths :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 do return -1
	n64, m64 := input[0], input[1]
	if n64 < 1 || n64 > N || m64 < 0 || m64 > M do return -1
	qp := c.size_t(2 + 2*m64)
	if length < qp+1 do return -1
	q64 := input[qp]
	if q64 < 1 || q64 > Q || length != qp+1+3*c.size_t(q64) do return -1
	n, m, q := int(n64), int(m64), int(q64)
	var adj: [N][M]int
	var degree: [N]int
	for i := 0; i < m; i += 1 {
		u64, v64 := input[2+2*i], input[3+2*i]
		if u64 < 0 || u64 >= n64 || v64 <= u64 || v64 >= n64 do return -1
		u := int(u64); adj[u][degree[u]] = int(v64); degree[u] += 1
	}
	var modes, starts, dests: [Q]int
	for i := 0; i < q; i += 1 {
		p := qp+1+3*c.size_t(i); mode, start, dest := input[p], input[p+1], input[p+2]
		if mode < 0 || mode > 1 || start < 0 || start >= n64 || dest < 0 || dest >= n64 do return -1
		modes[i], starts[i], dests[i] = int(mode), int(start), int(dest)
	}
	var lens: [Q]int
	var paths: [Q][N]int
	words: c.size_t = 0
	for qi := 0; qi < q; qi += 1 {
		start, dest := starts[qi], dests[qi]
		lens[qi] = -1
		if modes[qi] == 0 {
			var stack, next_edge: [N+1]int
			var visited: [N]bool
			depth := 0; stack[0] = start; visited[start] = true
			for {
				current := stack[depth]
				if current == dest { lens[qi] = depth; for j := 0; j < depth; j += 1 { paths[qi][j] = stack[j+1] }; break }
				if next_edge[depth] < degree[current] {
					next := adj[current][next_edge[depth]]; next_edge[depth] += 1
					if !visited[next] { visited[next] = true; depth += 1; stack[depth] = next; next_edge[depth] = 0 }
				} else if depth == 0 { break } else { depth -= 1 }
			}
		} else {
			var parent: [N]int; for i := 0; i < N; i += 1 { parent[i] = -1 }
			var queue: [N]int; head, tail := 0, 0; parent[start] = start; queue[tail] = start; tail += 1
			for head < tail { current := queue[head]; head += 1; if current == dest { break }; for j := 0; j < degree[current]; j += 1 { next := adj[current][j]; if parent[next] == -1 { parent[next] = current; queue[tail] = next; tail += 1 } } }
			if parent[dest] != -1 { var reverse: [N]int; count := 0; current := dest; for current != start { reverse[count] = current; count += 1; current = parent[current] }; lens[qi] = count; for j := 0; j < count; j += 1 { paths[qi][j] = reverse[count-1-j] } }
		}
		words += 1; if lens[qi] > 0 { words += c.size_t(lens[qi]) }
	}
	required := words*8
	if output == nil || capacity < required do return -2
	word: c.size_t = 0
	for qi := 0; qi < q; qi += 1 { put_i64(output, word, i64(lens[qi])); word += 1; for j := 0; j < lens[qi]; j += 1 { put_i64(output, word, i64(paths[qi][j])); word += 1 } }
	return i64(required)
}
