package cocomparability_ldfs_minimum_path_cover

import "core:c"

MAX_N :: 8
MAX_PARSEABLE :: 18

@(export)
cocomparability_ldfs_minimum_path_cover :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE) do return -1
	n_value := input[0]
	if n_value < 1 || n_value > MAX_N do return -1
	n := int(n_value)
	if int(length) != 1 + 2*n do return -1
	full := u16((1 << n) - 1)
	adjacency: [MAX_N]u16
	order, rank, position: [MAX_N]int
	seen_order: [MAX_N]bool
	for v := 0; v < n; v += 1 {
		row := input[1+v]
		if row < 0 do return -1
		if u64(row) > u64(full) || row & (i64(1) << v) != 0 do return -1
		adjacency[v] = u16(row)
	}
	for u := 0; u < n; u += 1 {
		for v := 0; v < n; v += 1 {
			if ((adjacency[u] >> u16(v)) & 1) != ((adjacency[v] >> u16(u)) & 1) do return -1
		}
	}
	for i := 0; i < n; i += 1 {
		value := input[1+n+i]
		if value < 0 || value >= n_value || seen_order[int(value)] do return -1
		order[i] = int(value)
		rank[int(value)] = i
		seen_order[int(value)] = true
	}
	for i := 0; i < n; i += 1 {
		for j := i+1; j < n; j += 1 {
			for k := j+1; k < n; k += 1 {
				a, b, d := order[i], order[j], order[k]
				if (adjacency[a] >> u16(d)) & 1 != 0 && (adjacency[a] >> u16(b)) & 1 == 0 && (adjacency[b] >> u16(d)) & 1 == 0 do return -1
			}
		}
	}
	reached: [MAX_N]bool
	queue: [MAX_N]int
	head, tail := 0, 1
	queue[0] = 0
	reached[0] = true
	for head < tail {
		u := queue[head]
		head += 1
		for v := 0; v < n; v += 1 {
			if (adjacency[u] & (u16(1) << u16(v))) != 0 && !reached[v] {
				reached[v] = true
				queue[tail] = v
				tail += 1
			}
		}
	}
	for v := 0; v < n; v += 1 { if !reached[v] do return -1 }

	labels: [MAX_N]u64
	visited: [MAX_N]bool
	ldfs: [MAX_N]int
	for step := 1; step <= n; step += 1 {
		chosen := -1
		for v := 0; v < n; v += 1 {
			if !visited[v] && (chosen < 0 || labels[v] > labels[chosen] || (labels[v] == labels[chosen] && rank[v] > rank[chosen])) do chosen = v
		}
		ldfs[step-1] = chosen
		visited[chosen] = true
		for v := 0; v < n; v += 1 {
			if !visited[v] && adjacency[chosen] & (u16(1) << u16(v)) != 0 {
				labels[v] = (labels[v] >> 4) | (u64(step) << 60)
			}
		}
	}
	for i := 0; i < n; i += 1 { position[ldfs[i]] = i }
	for v := 0; v < n; v += 1 { visited[v] = false }
	paths := 0
	for {
		current := -1
		for v := 0; v < n; v += 1 {
			if !visited[v] && (current < 0 || position[v] > position[current]) do current = v
		}
		if current < 0 do break
		paths += 1
		visited[current] = true
		for {
			next := -1
			for v := 0; v < n; v += 1 {
				if !visited[v] && adjacency[current] & (u16(1) << u16(v)) != 0 && (next < 0 || position[v] > position[next]) do next = v
			}
			if next < 0 do break
			visited[next] = true
			current = next
		}
	}
	return i64(paths)
}
