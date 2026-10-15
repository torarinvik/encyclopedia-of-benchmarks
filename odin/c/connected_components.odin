package connected_components

import "core:c"

Max_Vertices :: 256

visit :: proc(vertex, n: int, adjacency: [^]bool, seen: [^]bool) {
	seen[vertex] = true
	for next := 0; next < n; next += 1 {
		if adjacency[vertex * Max_Vertices + next] && !seen[next] { visit(next, n, adjacency, seen) }
	}
}

@(export)
connected_components :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > 1026 do return -1
	if input[0] < 0 || input[0] > 256 || input[1] < 0 || input[1] > 512 do return -1
	n := int(input[0]); m := int(input[1])
	if int(length) != 2 + 2 * m do return -1
	adjacency: [Max_Vertices * Max_Vertices]bool = {}
	for i := 0; i < m; i += 1 {
		u := input[2 + 2 * i]; v := input[3 + 2 * i]
		if u < 1 || u > i64(n) || v < 1 || v > i64(n) do return -1
		a := int(u - 1); b := int(v - 1)
		adjacency[a * Max_Vertices + b] = true; adjacency[b * Max_Vertices + a] = true
	}
	seen: [Max_Vertices]bool = {}
	components: i64 = 0
	for i := 0; i < n; i += 1 {
		if !seen[i] { visit(i, n, &adjacency[0], &seen[0]); components += 1 }
	}
	return components
}
