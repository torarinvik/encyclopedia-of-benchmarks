module yens_kshortest_paths

struct Path {
	mut:
	len int
	nodes [8]i64
	cost i64
}

fn less(a Path, b Path) bool {
	if a.cost != b.cost { return a.cost < b.cost }
	limit := if a.len < b.len { a.len } else { b.len }
	for i in 0 .. limit { if a.nodes[i] != b.nodes[i] { return a.nodes[i] < b.nodes[i] } }
	return a.len < b.len
}
fn same(a Path, b Path) bool {
	if a.len != b.len { return false }
	for i in 0 .. a.len { if a.nodes[i] != b.nodes[i] { return false } }
	return true
}
fn begins(a Path, root Path, count int) bool {
	if a.len < count || root.len < count { return false }
	for i in 0 .. count { if a.nodes[i] != root.nodes[i] { return false } }
	return true
}
fn shortest(n int, src int, dst int, graph [64]i64, blocked_nodes [8]bool, blocked_edges [64]bool) ?Path {
	mut current := [8]i64{}
	mut next_vertex := [8]int{}
	mut path_cost := [8]i64{}
	mut depth := 1
	current[0] = i64(src)
	mut found := false
	mut best := Path{}
	for depth > 0 {
		u := int(current[depth-1])
		if u == dst {
			candidate := Path{len: depth, nodes: current, cost: path_cost[depth-1]}
			if !found || less(candidate, best) { best = candidate; found = true }
			depth--
			continue
		}
		if next_vertex[depth-1] >= n { next_vertex[depth-1] = 0; depth--; continue }
		v := next_vertex[depth-1]
		next_vertex[depth-1]++
		weight := graph[u*n+v]
		if weight < 0 || blocked_nodes[v] || blocked_edges[u*8+v] { continue }
		mut repeated := false
		for j in 0 .. depth { if int(current[j]) == v { repeated = true } }
		if repeated { continue }
		current[depth] = i64(v)
		path_cost[depth] = path_cost[depth-1] + weight
		next_vertex[depth] = 0
		depth++
	}
	if found { return best }
	return none
}
fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[offset+b] = u8((bits >> u64(b*8)) & 255) } }
}

@[export: 'yens_kshortest_paths']
pub fn yens_kshortest_paths(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 4 { return -1 }
	nv := unsafe { input[0] }; kv := unsafe { input[1] }; srcv := unsafe { input[2] }; dstv := unsafe { input[3] }
	if nv < 1 || nv > 8 || kv < 1 || kv > 8 || srcv < 0 || srcv >= nv || dstv < 0 || dstv >= nv { return -1 }
	n := int(nv); k := int(kv); src := int(srcv); dst := int(dstv)
	if length != usize(4+n*n) { return -1 }
	mut graph := [64]i64{}
	for i in 0 .. n*n { w := unsafe { input[4+i] }; if w < -1 || w > 1000 { return -1 }; graph[i] = w }
	mut accepted := [8]Path{}; mut accepted_count := 0
	mut candidates := [64]Path{}; mut candidate_count := 0
	no_nodes := [8]bool{}; no_edges := [64]bool{}
	if first := shortest(n,src,dst,graph,no_nodes,no_edges) { accepted[0] = first; accepted_count = 1 }
	for accepted_count < k && accepted_count > 0 {
		last := accepted[accepted_count-1]
		for spur_index in 0 .. last.len-1 {
			mut root := Path{len: spur_index+1}
			for j in 0 .. root.len { root.nodes[j] = last.nodes[j] }
			for j in 0 .. spur_index { root.cost += graph[int(root.nodes[j])*n+int(root.nodes[j+1])] }
			mut blocked_nodes := [8]bool{}; mut blocked_edges := [64]bool{}
			for j in 0 .. spur_index { blocked_nodes[int(root.nodes[j])] = true }
			for p in 0 .. accepted_count {
				if begins(accepted[p],root,root.len) && accepted[p].len > root.len {
					u := int(accepted[p].nodes[spur_index]); v := int(accepted[p].nodes[spur_index+1]); blocked_edges[u*8+v] = true
				}
			}
			if spur := shortest(n,int(root.nodes[spur_index]),dst,graph,blocked_nodes,blocked_edges) {
				mut total := root
				for j in 1 .. spur.len { total.nodes[total.len] = spur.nodes[j]; total.len++ }
				total.cost += spur.cost
				mut duplicate := false
				for p in 0 .. accepted_count { if same(total,accepted[p]) { duplicate = true } }
				for p in 0 .. candidate_count { if same(total,candidates[p]) { duplicate = true } }
				if !duplicate && candidate_count < candidates.len { candidates[candidate_count] = total; candidate_count++ }
			}
		}
		if candidate_count == 0 { break }
		mut best := 0
		for i in 1 .. candidate_count { if less(candidates[i],candidates[best]) { best = i } }
		accepted[accepted_count] = candidates[best]; accepted_count++
		candidate_count--; candidates[best] = candidates[candidate_count]
	}
	mut bytes := 8
	for i in 0 .. accepted_count { bytes += (accepted[i].len+2)*8 }
	if unsafe { output == nil } || output_capacity < usize(bytes) { return -2 }
	put_i64(mut output,0,i64(accepted_count)); mut at := 8
	for i in 0 .. accepted_count { put_i64(mut output,at,i64(accepted[i].len)); at+=8; for j in 0 .. accepted[i].len { put_i64(mut output,at,accepted[i].nodes[j]); at+=8 }; put_i64(mut output,at,accepted[i].cost); at+=8 }
	return i64(bytes)
}
