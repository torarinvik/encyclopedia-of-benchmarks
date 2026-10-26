// Clean-room bounded port of GAPBS OrderedCount; see package LICENSE.txt.
@[export: 'gapbs_ordered_triangle_count']
pub fn gapbs_ordered_triangle_count(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 257 { return -1 }
		if input[0] < 1 || input[0] > 16 { return -1 }
		n := int(input[0])
		if length != usize(1 + n*n) { return -1 }
		mut adjacency := [16][16]i64{}
		mut neighbors := [16][16]int{}
		mut degree := [16]int{}
		for u in 0..n {
			for v in 0..n {
				edge := input[1 + u*n + v]
				if (edge != 0 && edge != 1) || (u == v && edge != 0) { return -1 }
				adjacency[u][v] = edge
			}
		}
		for u in 0..n {
			for v in (u+1)..n {
				if adjacency[u][v] != adjacency[v][u] { return -1 }
			}
		}
		for u in 0..n {
			for v in 0..n {
				if adjacency[u][v] != 0 {
					neighbors[u][degree[u]] = v
					degree[u]++
				}
			}
		}
		mut total := i64(0)
		for u in 0..n {
			for vi in 0..degree[u] {
				v := neighbors[u][vi]
				if v > u { break }
				mut edge_pos := 0
				for wi in 0..degree[u] {
					w := neighbors[u][wi]
					if w > v { break }
					for edge_pos < degree[v] && neighbors[v][edge_pos] < w { edge_pos++ }
					if edge_pos < degree[v] && neighbors[v][edge_pos] == w { total++ }
				}
			}
		}
		return total
	}
}
