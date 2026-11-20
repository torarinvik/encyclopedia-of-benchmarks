package wigderson_3_colorable_graph_coloring

import "core:c"

MAX_VERTICES :: 32
MAX_EDGES :: 128
MAX_INPUT :: 2 + 2 * MAX_EDGES

@(export)
wigderson_3_colorable_graph_coloring :: proc "c"(input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT + 1 do return -1
	if input[0] < 0 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES do return -1
	n := int(input[0])
	m := int(input[1])
	if int(length) != 2 + 2*m do return -1

	var adjacent: [MAX_VERTICES][MAX_VERTICES]bool
	for edge := 0; edge < m; edge += 1 {
		ru := input[2 + 2*edge]
		rv := input[3 + 2*edge]
		if ru < 0 || rv <= ru || rv >= i64(n) do return -1
		u, v := int(ru), int(rv)
		if adjacent[u][v] do return -1
		adjacent[u][v], adjacent[v][u] = true, true
	}

	var active: [MAX_VERTICES]bool
	var colors: [MAX_VERTICES]u8
	for v := 0; v < n; v += 1 do active[v] = true
	threshold := 0
	for (threshold+1)*(threshold+1) <= n do threshold += 1
	next_color := 1

	for {
		chosen, maximum_degree := n, 0
		for v := 0; v < n; v += 1 {
			if !active[v] do continue
			degree := 0
			for w := 0; w < n; w += 1 {
				if active[w] && adjacent[v][w] do degree += 1
			}
			if chosen == n || degree > maximum_degree { chosen, maximum_degree = v, degree }
		}
		if chosen == n || maximum_degree < threshold do break

		var in_neighborhood: [MAX_VERTICES]bool
		var side: [MAX_VERTICES]i8
		var queue: [MAX_VERTICES]int
		for v := 0; v < n; v += 1 {
			side[v] = -1
			in_neighborhood[v] = active[v] && adjacent[chosen][v]
		}
		for root := 0; root < n; root += 1 {
			if !in_neighborhood[root] || side[root] >= 0 do continue
			head, tail := 0, 0
			side[root], queue[tail] = 0, root
			tail += 1
			for head < tail {
				u := queue[head]
				head += 1
				for v := 0; v < n; v += 1 {
					if !in_neighborhood[v] || !adjacent[u][v] do continue
					if side[v] < 0 {
						side[v] = 1 - side[u]
						queue[tail] = v
						tail += 1
					} else if side[v] == side[u] { return -1 }
				}
			}
		}
		for v := 0; v < n; v += 1 {
			if in_neighborhood[v] do colors[v] = u8(next_color + int(side[v]))
		}
		colors[chosen] = u8(next_color + 2)
		active[chosen] = false
		for v := 0; v < n; v += 1 { if adjacent[chosen][v] do active[v] = false }
		next_color += 2
	}

	for v := 0; v < n; v += 1 {
		if !active[v] do continue
		var used: [MAX_VERTICES+2]bool
		for w := 0; w < n; w += 1 {
			if adjacent[v][w] && colors[w] > 0 do used[int(colors[w])] = true
		}
		candidate := next_color
		for candidate < MAX_VERTICES+2 && used[candidate] do candidate += 1
		if candidate >= MAX_VERTICES+2 do return -1
		colors[v] = u8(candidate)
	}

	palette: u8 = 0
	for v := 0; v < n; v += 1 { if colors[v] > palette do palette = colors[v] }
	output_bytes := n + 1
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	output[0] = palette
	for v := 0; v < n; v += 1 { output[v + 1] = colors[v] }
	return i64(output_bytes)
}
