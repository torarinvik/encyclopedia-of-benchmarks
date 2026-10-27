module weighted_greedy_spanner

const max_n = 8
const max_m = 28
const max_input = 88
const inf = i64(1) << 60

@[export: 'weighted_greedy_spanner']
pub fn weighted_greedy_spanner(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n64, m64, k := input[0], input[1], input[2]
		if n64 < 2 || n64 > 8 || m64 < 0 || m64 > 28 || k < 1 || k > 3 || length != usize(3+3*m64) { return -1 }
		n, m := int(n64), int(m64)
		mut edge_u := []i64{len: max_m, init: 0}
		mut edge_v := []i64{len: max_m, init: 0}
		mut edge_w := []i64{len: max_m, init: 0}
		mut order := []int{len: max_m, init: 0}
		mut adjacency := [][]i64{len: max_n, init: []i64{len: max_n, init: i64(0)}}
		mut selected := []u8{len: max_m, init: 0}
		for i in 0 .. m {
			edge_u[i] = input[3+3*i]
			edge_v[i] = input[4+3*i]
			edge_w[i] = input[5+3*i]
			if edge_u[i] < 0 || edge_v[i] <= edge_u[i] || edge_v[i] >= n64 || edge_w[i] < 1 || edge_w[i] > 32 { return -1 }
			for j in 0 .. i { if edge_u[j] == edge_u[i] && edge_v[j] == edge_v[i] { return -1 } }
			order[i] = i
		}
		for i in 1 .. m {
			key := order[i]
			mut pos := i
			for pos > 0 {
				prev := order[pos-1]
				if edge_w[prev] < edge_w[key] || (edge_w[prev] == edge_w[key] && edge_u[prev] < edge_u[key]) ||
					(edge_w[prev] == edge_w[key] && edge_u[prev] == edge_u[key] && edge_v[prev] <= edge_v[key]) { break }
				order[pos] = prev
				pos--
			}
			order[pos] = key
		}
		if output == nil || capacity < m { return -2 }
		for rank in 0 .. m {
			edge := order[rank]
			source, target := int(edge_u[edge]), int(edge_v[edge])
			mut distance := []i64{len: max_n, init: inf}
			mut settled := []bool{len: max_n, init: false}
			distance[source] = 0
			for _ in 0 .. n {
				mut vertex := n
				for v in 0 .. n { if !settled[v] && (vertex == n || distance[v] < distance[vertex]) { vertex = v } }
				if vertex == n || distance[vertex] == inf { break }
				settled[vertex] = true
				for v in 0 .. n {
					weight := adjacency[vertex][v]
					if weight > 0 && distance[v] > distance[vertex]+weight { distance[v] = distance[vertex]+weight }
				}
			}
			if distance[target] > (2*k-1)*edge_w[edge] {
				selected[edge] = 1
				adjacency[source][target] = edge_w[edge]
				adjacency[target][source] = edge_w[edge]
			}
		}
		for i in 0 .. m { output[i] = selected[i] }
		return i64(m)
	}
}
