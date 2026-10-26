@[export: 'gapbs_pagerank_pull_gs']
pub fn gapbs_pagerank_pull_gs(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 6 || length > 66 { return -1 }
		n64 := input[0]
		iterations64 := input[1]
		if n64 < 2 || n64 > 8 || iterations64 < 0 || iterations64 > 20 { return -1 }
		n := int(n64)
		iterations := int(iterations64)
		if length != usize(2 + n*n) { return -1 }
		mut matrix := []u8{len: 64, init: 0}
		mut outdegree := []int{len: 8, init: 0}
		for row in 0 .. n {
			for column in 0 .. n {
				value := input[2 + row*n + column]
				if (value != 0 && value != 1) || (row == column && value != 0) { return -1 }
				matrix[row*n+column] = u8(value)
				outdegree[row] += int(value)
			}
			if outdegree[row] == 0 { return -1 }
		}
		damping := f32(0.85)
		init_score := f32(1.0) / f32(n)
		base_score := (f32(1.0) - damping) / f32(n)
		mut scores := []f32{len: 8, init: 0}
		mut outgoing := []f32{len: 8, init: 0}
		for node in 0 .. n {
			scores[node] = init_score
			outgoing[node] = init_score / f32(outdegree[node])
		}
		for _ in 0 .. iterations {
			for target in 0 .. n {
				mut incoming := f32(0.0)
				for source in 0 .. n {
					if matrix[source*n+target] != 0 { incoming += outgoing[source] }
				}
				scores[target] = base_score + damping * incoming
				outgoing[target] = scores[target] / f32(outdegree[target])
			}
		}
		mut weighted := f64(0.0)
		for node in 0 .. n { weighted += f64(node+1) * f64(scores[node]) }
		return i64(weighted * 100.0 + 0.5)
	}
}
