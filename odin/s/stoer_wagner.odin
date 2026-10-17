package stoer_wagner

import "core:c"

MAX_N :: 16
MAX_INPUT_VALUES :: 257
MAX_WEIGHT :: i64(1_000_000)

@(export)
stoer_wagner :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_VALUES) do return -1
	n_value := input[0]
	if n_value < 2 || n_value > MAX_N do return -1
	n := int(n_value)
	if length != c.size_t(1 + n * n) do return -1

	var graph: [MAX_N * MAX_N]i64
	for row := 0; row < n; row += 1 {
		for column := 0; column < n; column += 1 {
			weight := input[1 + row * n + column]
			if weight < 0 || weight > MAX_WEIGHT do return -1
			graph[row * MAX_N + column] = weight
		}
	}
	for row := 0; row < n; row += 1 {
		if graph[row * MAX_N + row] != 0 do return -1
		for column := row + 1; column < n; column += 1 {
			if graph[row * MAX_N + column] != graph[column * MAX_N + row] do return -1
		}
	}

	var merged: [MAX_N]bool
	min_cut := i64(120_000_001)
	for phase := 0; phase < n - 1; phase += 1 {
		var in_set: [MAX_N]bool
		var weights: [MAX_N]i64
		previous := -1
		last := -1
		for _ in 0..<(n - phase) {
			current := -1
			max_weight := i64(-1)
			for vertex := 0; vertex < n; vertex += 1 {
				if !merged[vertex] && !in_set[vertex] && weights[vertex] > max_weight {
					max_weight = weights[vertex]
					current = vertex
				}
			}
			if current < 0 do break
			in_set[current] = true
			previous = last
			last = current
			for vertex := 0; vertex < n; vertex += 1 {
				if !merged[vertex] && !in_set[vertex] {
					weights[vertex] += graph[current * MAX_N + vertex]
				}
			}
		}
		if last < 0 || previous < 0 do return -1
		if weights[last] < min_cut do min_cut = weights[last]
		for vertex := 0; vertex < n; vertex += 1 {
			graph[previous * MAX_N + vertex] += graph[last * MAX_N + vertex]
			graph[vertex * MAX_N + previous] = graph[previous * MAX_N + vertex]
		}
		merged[last] = true
	}
	return min_cut
}
