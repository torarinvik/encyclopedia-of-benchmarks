module thomassen_convex_drawing_extendibility

const nmax = 8
const mmax = 18
const fmax = 12
const input_max = 93
const flow_nodes = 18

fn th_connected(adjacency [][]bool, n int, removed int) bool {
	start := if removed == 0 { 1 } else { 0 }
	mut seen := []bool{len: nmax, init: false}
	mut stack := []int{len: nmax, init: 0}
	mut top := 1
	mut count := 0
	seen[start] = true
	stack[0] = start
	for top > 0 {
		top--
		u := stack[top]
		count++
		for v in 0 .. n {
			if v != removed && adjacency[u][v] && !seen[v] {
				seen[v] = true
				stack[top] = v
				top++
			}
		}
	}
	expected := n
	if removed >= 0 { expected-- }
	return count == expected
}

fn th_three_outer_paths(adjacency [][]bool, outer []bool, n int, root int) bool {
	mut residual := [][]int{len: flow_nodes, init: []int{len: flow_nodes, init: 0}}
	source := 2 * n
	sink := source + 1
	nodes := sink + 1
	for v in 0 .. n { if v != root { residual[2*v][2*v+1] = 1 } }
	for u in 0 .. n {
		for v in (u+1) .. n {
			if !adjacency[u][v] { continue }
			if u == root { residual[source][2*v]++ }
			else if v == root { residual[source][2*u]++ }
			else { residual[2*u+1][2*v]++; residual[2*v+1][2*u]++ }
		}
	}
	for v in 0 .. n { if outer[v] && v != root { residual[2*v+1][sink]++ } }
	for _ in 0 .. 3 {
		mut parent := []int{len: flow_nodes, init: -1}
		mut queue := []int{len: flow_nodes, init: 0}
		parent[source] = source
		mut head := 0
		mut tail := 1
		queue[0] = source
		for head < tail && parent[sink] < 0 {
			u := queue[head]
			head++
			for v in 0 .. nodes {
				if residual[u][v] > 0 && parent[v] < 0 {
					parent[v] = u
					queue[tail] = v
					tail++
					if v == sink { break }
				}
			}
		}
		if parent[sink] < 0 { return false }
		mut v := sink
		for v != source {
			u := parent[v]
			residual[u][v]--
			residual[v][u]++
			v = u
		}
	}
	return true
}

fn th_condition_three(inner [][]bool, degree []int, n int) bool {
	mut mask_size := []int{len: 1 << nmax, init: 0}
	for mask in 1 .. (1 << n) { mask_size[mask] = mask_size[mask >> 1] + (mask & 1) }
	for start in 0 .. n {
		mut dp := [][]int{len: 1 << nmax, init: []int{len: nmax, init: 255}}
		dp[1 << start][start] = if degree[start] >= 3 { 1 } else { 0 }
		for mask in 0 .. (1 << n) {
			if (mask & (1 << start)) == 0 { continue }
			for last in start .. n {
				used := dp[mask][last]
				if used == 255 { continue }
				if mask_size[mask] >= 3 && inner[last][start] && used < 3 { return false }
				for next in (start+1) .. n {
					bit := 1 << next
					if (mask & bit) != 0 || !inner[last][next] { continue }
					candidate := used
					if degree[next] >= 3 { candidate++ }
					next_mask := mask | bit
					if candidate < dp[next_mask][next] { dp[next_mask][next] = candidate }
				}
			}
		}
	}
	return true
}

@[export: 'thomassen_convex_drawing_extendibility']
pub fn thomassen_convex_drawing_extendibility(input &i64, input_length usize) i64 {
	unsafe {
		if input == nil || input_length < 5 || input_length > input_max { return -1 }
		n0 := input[0]
		m0 := input[1]
		f0 := input[2]
		outer0 := input[3]
		sides0 := input[4]
		if n0 < 3 || n0 > nmax || m0 < n0 || m0 > mmax || m0 > 3*n0-6 || f0 < 2 || f0 > fmax ||
			f0 != m0-n0+2 || outer0 < 0 || outer0 >= f0 || sides0 < 3 || sides0 > n0 { return -1 }
		n := int(n0)
		m := int(m0)
		f := int(f0)
		outer_id := int(outer0)
		side_count := int(sides0)
		mut adjacency := [][]bool{len: nmax, init: []bool{len: nmax, init: false}}
		mut edge_u := []int{len: mmax, init: 0}
		mut edge_v := []int{len: mmax, init: 0}
		mut cursor := 5
		for e in 0 .. m {
			if cursor + 2 > int(input_length) { return -1 }
			u0 := input[cursor]
			v0 := input[cursor+1]
			cursor += 2
			if u0 < 0 || u0 >= v0 || v0 >= n0 { return -1 }
			u := int(u0)
			v := int(v0)
			if adjacency[u][v] || (e > 0 && (u < edge_u[e-1] || (u == edge_u[e-1] && v <= edge_v[e-1]))) { return -1 }
			adjacency[u][v] = true
			adjacency[v][u] = true
			edge_u[e] = u
			edge_v[e] = v
		}
		mut faces := [][]int{len: fmax, init: []int{len: nmax, init: 0}}
		mut widths := []int{len: fmax, init: 0}
		mut darts := [][]int{len: nmax, init: []int{len: nmax, init: 0}}
		for face in 0 .. f {
			if cursor >= int(input_length) { return -1 }
			width0 := input[cursor]
			cursor++
			if width0 < 3 || width0 > n0 || cursor + int(width0) > int(input_length) { return -1 }
			width := int(width0)
			widths[face] = width
			mut row := []bool{len: nmax, init: false}
			for i in 0 .. width {
				x0 := input[cursor]
				cursor++
				if x0 < 0 || x0 >= n0 { return -1 }
				x := int(x0)
				if row[x] { return -1 }
				row[x] = true
				faces[face][i] = x
			}
			for i in 0 .. width {
				u := faces[face][i]
				v := faces[face][(i+1)%width]
				if !adjacency[u][v] { return -1 }
				darts[u][v]++
			}
		}
		if cursor + side_count != int(input_length) { return -1 }
		mut apex := []int{len: nmax, init: 0}
		for i in 0 .. side_count {
			pos := input[cursor]
			cursor++
			if pos < 0 || pos >= widths[outer_id] || (i > 0 && pos <= apex[i-1]) { return -1 }
			apex[i] = int(pos)
		}
		for e in 0 .. m { if darts[edge_u[e]][edge_v[e]] != 1 || darts[edge_v[e]][edge_u[e]] != 1 { return -1 } }
		if !th_connected(adjacency, n, -1) { return -1 }
		for v in 0 .. n { if !th_connected(adjacency, n, v) { return -1 } }
		mut link_adj := []bool{len: nmax*nmax*nmax, init: false}
		mut link_degree := [][]int{len: nmax, init: []int{len: nmax, init: 0}}
		for face in 0 .. f {
			for i in 0 .. widths[face] {
				center := faces[face][i]
				before := faces[face][(i+widths[face]-1)%widths[face]]
				after := faces[face][(i+1)%widths[face]]
				if before == after { return -1 }
				link_adj[center*nmax*nmax+before*nmax+after] = true
				link_adj[center*nmax*nmax+after*nmax+before] = true
				link_degree[center][before]++
				link_degree[center][after]++
			}
		}
		mut outer_v := []bool{len: nmax, init: false}
		mut outer_e := [][]bool{len: nmax, init: []bool{len: nmax, init: false}}
		for i in 0 .. widths[outer_id] {
			u := faces[outer_id][i]
			v := faces[outer_id][(i+1)%widths[outer_id]]
			outer_v[u] = true
			outer_e[u][v] = true
			outer_e[v][u] = true
		}
		for center in 0 .. n {
			mut seed := -1
			mut incident := 0
			for v in 0 .. n {
				if adjacency[center][v] {
					if link_degree[center][v] != 2 { return -1 }
					if seed < 0 { seed = v }
					incident++
				} else if link_degree[center][v] != 0 { return -1 }
			}
			if seed < 0 { return -1 }
			mut seen := []bool{len: nmax, init: false}
			mut stack := []int{len: nmax, init: 0}
			mut top := 1
			mut reached := 0
			seen[seed] = true
			stack[0] = seed
			for top > 0 {
				top--
				v := stack[top]
				reached++
				for w in 0 .. n {
					if link_adj[center*nmax*nmax+v*nmax+w] && !seen[w] { seen[w] = true; stack[top] = w; top++ }
				}
			}
			if reached != incident { return -1 }
		}
		mut face_a := []int{len: mmax, init: -1}
		mut face_b := []int{len: mmax, init: -1}
		mut face_use := []int{len: mmax, init: 0}
		for face in 0 .. f {
			for i in 0 .. widths[face] {
				u := faces[face][i]
				v := faces[face][(i+1)%widths[face]]
				lo := if u < v { u } else { v }
				hi := if u < v { v } else { u }
				mut found := -1
				for e in 0 .. m { if edge_u[e] == lo && edge_v[e] == hi { found = e; break } }
				if found < 0 || face_use[found] >= 2 { return -1 }
				if face_use[found] == 0 { face_a[found] = face } else { face_b[found] = face }
				face_use[found]++
			}
		}
		for e in 0 .. m { if face_use[e] != 2 || face_a[e] == face_b[e] { return -1 } }
		mut sides := [][]bool{len: nmax, init: []bool{len: nmax, init: false}}
		for s in 0 .. side_count {
			mut at := apex[s]
			end := apex[(s+1)%side_count]
			for {
				sides[s][faces[outer_id][at]] = true
				if at == end { break }
				at = (at+1)%widths[outer_id]
			}
		}
		mut degree := []int{len: nmax, init: 0}
		for u in 0 .. n { for v in 0 .. n { if adjacency[u][v] { degree[u]++ } } }
		for root in 0 .. n { if !outer_v[root] && degree[root] >= 3 && !th_three_outer_paths(adjacency, outer_v, n, root) { return 0 } }
		mut seen_inner := []bool{len: nmax, init: false}
		for seed in 0 .. n {
			if outer_v[seed] || seen_inner[seed] { continue }
			mut border := []bool{len: nmax, init: false}
			mut stack := []int{len: nmax, init: 0}
			mut top := 1
			seen_inner[seed] = true
			stack[0] = seed
			for top > 0 {
				top--
				u := stack[top]
				for v in 0 .. n {
					if !adjacency[u][v] { continue }
					if outer_v[v] { border[v] = true }
					else if !seen_inner[v] { seen_inner[v] = true; stack[top] = v; top++ }
				}
			}
			for s in 0 .. side_count {
				mut nonempty := false
				mut contained := true
				for v in 0 .. n { if border[v] { nonempty = true; if !sides[s][v] { contained = false } } }
				if nonempty && contained { return 0 }
			}
		}
		for e in 0 .. m {
			u := edge_u[e]
			v := edge_v[e]
			if !outer_e[u][v] { for s in 0 .. side_count { if sides[s][u] && sides[s][v] { return 0 } } }
		}
		mut inner := [][]bool{len: nmax, init: []bool{len: nmax, init: false}}
		for e in 0 .. m { u := edge_u[e]; v := edge_v[e]; if !outer_e[u][v] { inner[u][v] = true; inner[v][u] = true } }
		if th_condition_three(inner, degree, n) { return 1 }
		return 0
	}
}
