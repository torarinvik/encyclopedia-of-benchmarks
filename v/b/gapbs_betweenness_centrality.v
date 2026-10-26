// Clean-room bounded Brandes profile; see package LICENSE.txt.
@[export: 'gapbs_betweenness_centrality']
pub fn gapbs_betweenness_centrality(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 12 || length > 74 { return -1 }
		if input[0] < 3 || input[0] > 8 || input[1] < 1 || input[1] > input[0] { return -1 }
		n := int(input[0])
		k := int(input[1])
		if length != usize(2 + k + n*n) { return -1 }
		mut sources := [8]int{}
		for i in 0 .. k {
			raw := input[2+i]
			if raw < 0 || raw >= i64(n) { return -1 }
			sources[i] = int(raw)
			for j in 0 .. i { if sources[j] == sources[i] { return -1 } }
		}
		mut adjacency := [8][8]int{}
		for u in 0 .. n {
			for v in 0 .. n {
				edge := input[2+k+u*n+v]
				if (edge != 0 && edge != 1) || (u == v && edge != 0) { return -1 }
				adjacency[u][v] = int(edge)
			}
		}
		for u in 0 .. n {
			for v in (u+1) .. n { if adjacency[u][v] != adjacency[v][u] { return -1 } }
		}

		mut scores := [8]f32{}
		for si in 0 .. k {
			mut depth := [8]int{}
			mut queue := [8]int{}
			mut paths := [8]f64{}
			mut delta := [8]f32{}
			for v in 0 .. n { depth[v] = -1 }
			source := sources[si]
			depth[source] = 0
			paths[source] = 1.0
			mut head := 0
			mut tail := 1
			queue[0] = source
			for head < tail {
				u := queue[head]
				head++
				for v in 0 .. n {
					if adjacency[u][v] != 0 {
						if depth[v] == -1 {
							depth[v] = depth[u] + 1
							queue[tail] = v
							tail++
						}
						if depth[v] == depth[u] + 1 { paths[v] += paths[u] }
					}
				}
			}
			mut max_depth := 0
			for v in 0 .. n { if depth[v] > max_depth { max_depth = depth[v] } }
			mut d := max_depth
			for d >= 0 {
				for u in 0 .. n {
					if depth[u] == d {
						mut delta_u := f32(0.0)
						for v in 0 .. n {
							if adjacency[u][v] != 0 && depth[v] == d + 1 {
								one_plus := f32(1.0) + delta[v]
								contribution := (paths[u] / paths[v]) * f64(one_plus)
								delta_u = f32(f64(delta_u) + contribution)
							}
						}
						delta[u] = delta_u
						scores[u] = f32(f64(scores[u]) + f64(delta_u))
					}
				}
				d--
			}
		}
		mut biggest := f32(0.0)
		for v in 0 .. n { if scores[v] > biggest { biggest = scores[v] } }
		if !(biggest > 0.0) { return -1 }
		mut checksum := i64(0)
		for v in 0 .. n {
			normalized := scores[v] / biggest
			qscore := i64(f64(normalized)*1000.0 + 0.5)
			checksum += i64(v+1) * qscore
		}
		return checksum
	}
}
