// Clean-room Goldberg exact maximum-density profile.
module goldberg_maximum_density_subgraph

const max_n = 8
const max_m = 28
const max_network = 10

@[export: 'goldberg_maximum_density_subgraph']
pub fn goldberg_maximum_density_subgraph(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 59 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 2 || n64 > max_n || m64 < 0 || m64 > max_m || length != usize(2 + 2 * m64) { return -1 }
		n := int(n64)
		m := int(m64)
		mut adjacent := []bool{len: max_n * max_n, init: false}
		mut degree := []i64{len: max_n, init: 0}
		mut edge_u := []int{len: max_m, init: 0}
		mut edge_v := []int{len: max_m, init: 0}
		for edge in 0 .. m {
			u64 := input[2 + 2 * edge]
			v64 := input[3 + 2 * edge]
			if u64 < 0 || u64 >= v64 || v64 >= n64 { return -1 }
			u := int(u64)
			v := int(v64)
			if adjacent[u * max_n + v] { return -1 }
			adjacent[u * max_n + v] = true
			adjacent[v * max_n + u] = true
			edge_u[edge] = u
			edge_v[edge] = v
			degree[u]++
			degree[v]++
		}
		if m == 0 { return 1 }
		mut low := i64(0)
		mut high := m64
		mut denominator := i64(1)
		mut best := []bool{len: max_n, init: false}
		for (high - low) * n64 * (n64 - 1) >= denominator {
			low2 := 2 * low
			high2 := 2 * high
			midpoint := low + high
			next_denominator := 2 * denominator
			source := n
			sink := n + 1
			network_size := n + 2
			mut residual := []i64{len: max_network * max_network, init: 0}
			for vtx in 0 .. n {
				source_capacity := m64 * next_denominator
				residual[source * max_network + vtx] = source_capacity
				residual[vtx * max_network + sink] = source_capacity + 2 * midpoint - next_denominator * degree[vtx]
			}
			for edge in 0 .. m {
				u := edge_u[edge]
				v := edge_v[edge]
				residual[u * max_network + v] += next_denominator
				residual[v * max_network + u] += next_denominator
			}
			for {
				mut parent := []int{len: max_network, init: -1}
				mut queue := []int{len: max_network, init: 0}
				mut head := 0
				mut tail := 0
				parent[source] = source
				queue[tail] = source
				tail++
				for head < tail && parent[sink] == -1 {
					here := queue[head]
					head++
					for there in 0 .. network_size {
						if parent[there] == -1 && residual[here * max_network + there] > 0 {
							parent[there] = here
							queue[tail] = there
							tail++
							if there == sink { break }
						}
					}
				}
				if parent[sink] == -1 { break }
				mut amount := i64(1) << 60
				mut vertex := sink
				for vertex != source {
					previous := parent[vertex]
					if residual[previous * max_network + vertex] < amount { amount = residual[previous * max_network + vertex] }
					vertex = previous
				}
				vertex = sink
				for vertex != source {
					previous := parent[vertex]
					residual[previous * max_network + vertex] -= amount
					residual[vertex * max_network + previous] += amount
					vertex = previous
				}
			}
			mut reachable := []bool{len: max_network, init: false}
			mut queue2 := []int{len: max_network, init: 0}
			mut head2 := 0
			mut tail2 := 0
			reachable[source] = true
			queue2[tail2] = source
			tail2++
			for head2 < tail2 {
				here := queue2[head2]
				head2++
				for there in 0 .. network_size {
					if !reachable[there] && residual[here * max_network + there] > 0 {
						reachable[there] = true
						queue2[tail2] = there
						tail2++
					}
				}
			}
			mut selected := []bool{len: max_n, init: false}
			mut any := false
			for vtx in 0 .. n { selected[vtx] = reachable[vtx]; any = any || selected[vtx] }
			if any { best = selected; low = midpoint; high = high2 } else { low = low2; high = midpoint }
			denominator = next_denominator
		}
		mut vertex_count := i64(0)
		mut edge_count := i64(0)
		for vtx in 0 .. n { if best[vtx] { vertex_count++ } }
		if vertex_count == 0 { return 1 }
		for edge in 0 .. m { if best[edge_u[edge]] && best[edge_v[edge]] { edge_count++ } }
		mut a := edge_count
		mut b := vertex_count
		for b != 0 { r := a % b; a = b; b = r }
		return (edge_count / a) * (n64 + 1) + vertex_count / a
	}
}
