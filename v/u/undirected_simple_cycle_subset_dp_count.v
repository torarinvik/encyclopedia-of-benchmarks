// Clean-room all-length simple-cycle subset DP; see package RIGHTS.md.
module undirected_simple_cycle_subset_dp_count

const max_n = 14
const max_m = 91
const max_states = 1 << max_n

@[export: 'undirected_simple_cycle_subset_dp_count']
pub fn undirected_simple_cycle_subset_dp_count(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 185 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > max_n || m64 < 0 || m64 > n64*(n64-1)/2 || m64 > max_m { return -1 }
		n := int(n64)
		m := int(m64)
		if length != usize(2 + 2*m) { return -1 }

		mut adjacency := [14][14]bool{}
		mut neighbors := [14][14]int{}
		mut degree := [14]int{}
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
			adjacency[u][v] = true
			adjacency[v][u] = true
			neighbors[u][degree[u]] = v
			degree[u]++
			neighbors[v][degree[v]] = u
			degree[v]++
		}

		mut dp := [max_states * max_n]i64{}
		state_count := 1 << n
		for start in 0..n { dp[(1 << start)*max_n+start] = 1 }
		mut oriented_cycles := i64(0)
		for mask in 1..state_count {
			mut start := 0
			for (mask & (1 << start)) == 0 { start++ }
			mut cardinality := 0
			for vertex in 0..n { if (mask & (1 << vertex)) != 0 { cardinality++ } }
			for endpoint in 0..n {
				if (mask & (1 << endpoint)) == 0 { continue }
				ways := dp[mask*max_n+endpoint]
				if ways == 0 { continue }
				if cardinality >= 3 && adjacency[endpoint][start] { oriented_cycles += ways }
				for i in 0..degree[endpoint] {
					next := neighbors[endpoint][i]
					if next > start && (mask & (1 << next)) == 0 {
						dp[(mask | (1 << next))*max_n+next] += ways
					}
				}
			}
		}
		return oriented_cycles / 2
	}
}
