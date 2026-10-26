@[export: 'metric_tsp_tree_doubling']
pub fn metric_tsp_tree_doubling(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 65 { return -1 }
		n64 := input[0]
		if n64 < 1 || n64 > 8 || length != usize(1+n64*n64) { return -1 }
		n := int(n64)
		mut d := [][]i64{}
		for _ in 0 .. 8 { d << []i64{len: 8, init: 0} }
		for u in 0 .. n {
			for v in 0 .. n {
				w := input[1+u*n+v]
				if w < 0 || w > 10000 || (u == v && w != 0) { return -1 }
				d[u][v] = w
			}
		}
		for u in 0 .. n { for v in u+1 .. n { if d[u][v] != d[v][u] { return -1 } } }
		for u in 0 .. n { for v in 0 .. n { for k in 0 .. n { if d[u][v] > d[u][k]+d[k][v] { return -1 } } } }
		output_bytes := 8*(n+2)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut processed := [][]bool{}
		mut tree := [][]bool{}
		for _ in 0 .. 8 { processed << []bool{len: 8, init: false}; tree << []bool{len: 8, init: false} }
		mut parent := []int{len: n, init: 0}
		for i in 0 .. n { parent[i] = i }
		mut accepted := 0
		edge_count := n*(n-1)/2
		for _ in 0 .. edge_count {
			if accepted+1 >= n { break }
			mut bu, mut bv := 0, 0
			mut bw := i64(9223372036854775807)
			for u in 0 .. n { for v in u+1 .. n { if !processed[u][v] && d[u][v] < bw { bu, bv, bw = u, v, d[u][v] } } }
			processed[bu][bv] = true
			mut ru, mut rv := bu, bv
			for parent[ru] != ru { ru = parent[ru] }
			for parent[rv] != rv { rv = parent[rv] }
			if ru != rv { parent[rv] = ru; tree[bu][bv] = true; tree[bv][bu] = true; accepted++ }
		}
		mut stack := []int{len: 8, init: 0}
		mut order := []int{len: 8, init: 0}
		mut visited := []bool{len: 8, init: false}
		mut top, mut count := 1, 0
		for top > 0 {
			top--
			v := stack[top]
			if visited[v] { continue }
			visited[v] = true
			order[count] = v
			count++
			for rev := n-1; rev >= 0; rev-- { if tree[v][rev] && !visited[rev] { stack[top] = rev; top++ } }
		}
		mut cost := i64(0)
		for i in 0 .. n-1 { cost += d[order[i]][order[i+1]] }
		cost += d[order[n-1]][0]
		values := []i64{len: n+2, init: 0}
		values[0] = cost
		for i in 0 .. n { values[i+1] = i64(order[i]) }
		values[n+1] = 0
		for index, value in values {
			bits := u64(value)
			for byte in 0 .. 8 { output[8*index+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
