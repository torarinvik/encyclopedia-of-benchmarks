// Clean-room degree-oriented simple C4 counter; see package RIGHTS.md.
@[export: 'undirected_four_cycle_count_degree_order']
pub fn undirected_four_cycle_count_degree_order(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 131 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 { return -1 }
		n := int(n64)
		m := int(m64)
		if length != usize(2 + 2*m) { return -1 }

		mut neighbors := [16][16]int{}
		mut degree := [16]int{}
		mut previous_u := i64(-1)
		mut previous_v := i64(-1)
		for edge in 0..m {
			u64 := input[2+2*edge]
			v64 := input[3+2*edge]
			if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 >= v64 { return -1 }
			if edge != 0 && (u64 < previous_u || (u64 == previous_u && v64 <= previous_v)) { return -1 }
			previous_u = u64
			previous_v = v64
			u := int(u64)
			v := int(v64)
			neighbors[u][degree[u]] = v
			degree[u]++
			neighbors[v][degree[v]] = u
			degree[v]++
		}

		mut order := [16]int{}
		mut rank := [16]int{}
		for i in 0..n { order[i] = i }
		for i in 1..n {
			key := order[i]
			mut j := i
			for j > 0 {
				prior := order[j-1]
				if degree[prior] < degree[key] || (degree[prior] == degree[key] && prior < key) { break }
				order[j] = prior
				j--
			}
			order[j] = key
		}
		for i in 0..n { rank[order[i]] = i }

		mut count := [16]i64{}
		mut total := i64(0)
		for position in 0..n {
			pivot := order[position]
			for bi in 0..degree[pivot] {
				middle := neighbors[pivot][bi]
				if rank[middle] >= position { continue }
				for ci in 0..degree[middle] {
					opposite := neighbors[middle][ci]
					if rank[opposite] < position {
						total += count[opposite]
						count[opposite]++
					}
				}
			}
			for vertex in 0..n { count[vertex] = 0 }
		}
		return total
	}
}
