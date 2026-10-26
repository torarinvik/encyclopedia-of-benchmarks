package gapbs_pagerank_pull_gs

import "core:c"

@(export)
gapbs_pagerank_pull_gs :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 6 || length > 66 do return -1
	n64, iterations64 := input[0], input[1]
	if n64 < 2 || n64 > 8 || iterations64 < 0 || iterations64 > 20 do return -1
	n, iterations := int(n64), int(iterations64)
	if length != c.size_t(2+n*n) do return -1
	matrix: [64]u8
	outdegree: [8]int
	for row := 0; row < n; row += 1 {
		for column := 0; column < n; column += 1 {
			value := input[2+row*n+column]
			if (value != 0 && value != 1) || (row == column && value != 0) do return -1
			matrix[row*n+column] = u8(value)
			outdegree[row] += int(value)
		}
		if outdegree[row] == 0 do return -1
	}
	damping := f32(0.85)
	init_score := f32(1.0) / f32(n)
	base_score := (f32(1.0)-damping) / f32(n)
	scores: [8]f32
	outgoing: [8]f32
	for node := 0; node < n; node += 1 {
		scores[node] = init_score
		outgoing[node] = init_score / f32(outdegree[node])
	}
	for _ in 0..<iterations {
		for target := 0; target < n; target += 1 {
			incoming: f32 = 0
			for source := 0; source < n; source += 1 {
				if matrix[source*n+target] != 0 do incoming += outgoing[source]
			}
			scores[target] = base_score + damping*incoming
			outgoing[target] = scores[target] / f32(outdegree[target])
		}
	}
	weighted: f64 = 0
	for node := 0; node < n; node += 1 do weighted += f64(node+1)*f64(scores[node])
	return i64(weighted*100.0+0.5)
}
