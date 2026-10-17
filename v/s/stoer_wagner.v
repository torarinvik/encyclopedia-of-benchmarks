module stoer_wagner

@[export: 'stoer_wagner']
pub fn stoer_wagner(input &i64, length usize) i64 {
	if length < 1 || length > 257 { return -1 }
	unsafe {
		n_value := input[0]
		if n_value < 2 || n_value > 16 { return -1 }
		n := int(n_value)
		if length != usize(1 + n * n) { return -1 }

		mut graph := [][]i64{len: n, init: []i64{len: n, init: i64(0)}}
		for row := 0; row < n; row++ {
			for column := 0; column < n; column++ {
				weight := input[1 + row * n + column]
				if weight < 0 || weight > 1_000_000 { return -1 }
				graph[row][column] = weight
			}
		}
		for row := 0; row < n; row++ {
			if graph[row][row] != 0 { return -1 }
			for column := row + 1; column < n; column++ {
				if graph[row][column] != graph[column][row] { return -1 }
			}
		}

		mut merged := []bool{len: n, init: false}
		mut min_cut := i64(120_000_001)
		for phase := 0; phase < n - 1; phase++ {
			mut in_set := []bool{len: n, init: false}
			mut weights := []i64{len: n, init: i64(0)}
			mut previous := -1
			mut last := -1
			for _ in 0 .. n - phase {
				mut current := -1
				mut max_weight := i64(-1)
				for vertex := 0; vertex < n; vertex++ {
					if !merged[vertex] && !in_set[vertex] && weights[vertex] > max_weight {
						max_weight = weights[vertex]
						current = vertex
					}
				}
				if current < 0 { break }
				in_set[current] = true
				previous = last
				last = current
				for vertex := 0; vertex < n; vertex++ {
					if !merged[vertex] && !in_set[vertex] {
						weights[vertex] += graph[current][vertex]
					}
				}
			}
			if last < 0 || previous < 0 { return -1 }
			if weights[last] < min_cut { min_cut = weights[last] }
			for vertex := 0; vertex < n; vertex++ {
				graph[previous][vertex] += graph[last][vertex]
				graph[vertex][previous] = graph[previous][vertex]
			}
			merged[last] = true
		}
		return min_cut
	}
}
