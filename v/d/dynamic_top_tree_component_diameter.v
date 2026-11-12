module dynamic_top_tree_component_diameter

const max_n = 16
const max_q = 32
const max_e = 15
const max_nodes = 75
const max_input = 143
const edge_base = 0
const edge_compress = 1
const rake_zero = 2
const rake_merge = 3
const rake_branch = 4

struct Cluster {
mut:
	kind int
	a int
	b int
	c int
	parent int
	end0 int
	end1 int
	pivot int
	edge int
	length i64
	far0 i64
	far1 i64
	diameter i64
	best1 i64
	best2 i64
}

fn tt_far(nodes []Cluster, id int, vertex int) i64 {
	if nodes[id].end0 == vertex { return nodes[id].far0 }
	return nodes[id].far1
}

fn tt_recalc(mut nodes []Cluster, id int, weights []i64) {
	x := nodes[id]
	if x.kind == edge_base {
		w := weights[x.edge]
		nodes[id].length = w; nodes[id].far0 = w; nodes[id].far1 = w; nodes[id].diameter = w
	} else if x.kind == rake_zero {
		nodes[id].best1 = 0; nodes[id].best2 = 0; nodes[id].diameter = 0
	} else if x.kind == rake_merge {
		l := nodes[x.a]; r := nodes[x.b]
		mut first := i64(0); mut second := i64(0)
		for arm in [l.best1, l.best2, r.best1, r.best2] {
			if arm >= first { second = first; first = arm } else if arm > second { second = arm }
		}
		nodes[id].best1 = first; nodes[id].best2 = second
		nodes[id].diameter = max(l.diameter, max(r.diameter, l.best1+r.best1))
	} else if x.kind == rake_branch {
		e := nodes[x.a]; local := nodes[x.b]
		center := tt_far(nodes,x.a,x.end0); pivot_far := tt_far(nodes,x.a,x.pivot)
		nodes[id].best1 = max(center,e.length+local.best1); nodes[id].best2 = 0
		nodes[id].diameter = max(e.diameter,max(local.diameter,pivot_far+local.best1))
	} else {
		a := nodes[x.a]; b := nodes[x.b]; local := nodes[x.c]
		ay := tt_far(nodes,x.a,x.end0); ap := tt_far(nodes,x.a,x.pivot)
		bp := tt_far(nodes,x.b,x.pivot); bz := tt_far(nodes,x.b,x.end1)
		nodes[id].length = a.length+b.length
		nodes[id].far0 = max(ay,a.length+max(bp,local.best1))
		nodes[id].far1 = max(bz,b.length+max(ap,local.best1))
		nodes[id].diameter = max(a.diameter,max(b.diameter,max(local.diameter,max(ap+bp,max(ap+local.best1,bp+local.best1)))))
	}
}

fn tt_append(mut nodes []Cluster, mut count int, kind int, weights []i64,
	a int, b int, c int, end0 int, end1 int, pivot int, edge int) int {
	if count >= max_nodes { return -1 }
	id := count; count++
	nodes[id] = Cluster{kind:kind,a:a,b:b,c:c,parent:-1,end0:end0,end1:end1,pivot:pivot,edge:edge}
	if a >= 0 { nodes[a].parent = id }; if b >= 0 { nodes[b].parent = id }; if c >= 0 { nodes[c].parent = id }
	tt_recalc(mut nodes,id,weights)
	return id
}

fn tt_make_rake(mut nodes []Cluster, mut count int, weights []i64, base int,
	branches []int, branch_count int) int {
	mut level := []int{len:max_n+1}; mut next := []int{len:max_n+1}
	mut size := 1; level[0] = base
	for i in 0 .. branch_count { level[size] = branches[i]; size++ }
	for size > 1 {
		mut next_size := 0; mut i := 0
		for i < size {
			if i+1 == size { next[next_size] = level[i]; next_size++ }
			else {
				merged := tt_append(mut nodes,mut count,rake_merge,weights,level[i],level[i+1],-1,-1,-1,-1,-1)
				if merged < 0 { return -1 }; next[next_size] = merged; next_size++
			}
			i += 2
		}
		for j in 0 .. next_size { level[j] = next[j] }
		size = next_size
	}
	return level[0]
}

fn tt_neighbors(adj []bool, active []bool, n int, vertex int, mut out []int) int {
	mut count := 0
	for other in 0 .. n {
		if active[other] && adj[vertex*max_n+other] { if count < 2 { out[count] = other }; count++ }
	}
	return count
}

fn tt_find(mut parent []int, vertex int) int {
	mut v := vertex
	for parent[v] != v { parent[v] = parent[parent[v]]; v = parent[v] }
	return v
}

fn tt_store(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[offset+byte] = u8(bits >> (8*byte)) } }
}

@[export: 'dynamic_top_tree_component_diameter']
pub fn dynamic_top_tree_component_diameter(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(max_input) { return -1 }
	nv := unsafe { input[0] }; qv := unsafe { input[1] }
	if nv < 1 || nv > max_n || qv < 0 || qv > max_q { return -1 }
	n := int(nv); q := int(qv); edge_end := 2+3*(n-1)
	if length != usize(edge_end+3*q) { return -1 }
	mut edge_u := []int{len:max_e}; mut edge_v := []int{len:max_e}; mut dsu := []int{len:max_n}; mut weights := []i64{len:max_e}
	for v in 0 .. n { dsu[v] = v }
	for e in 0 .. n-1 {
		off := 2+3*e; uv := unsafe { input[off] }; vv := unsafe { input[off+1] }; w := unsafe { input[off+2] }
		if uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv || w < 0 || w > 1000 { return -1 }
		u := int(uv); v := int(vv); ru := tt_find(mut dsu,u); rv := tt_find(mut dsu,v)
		if ru == rv { return -1 }
		dsu[ru] = rv; edge_u[e] = u; edge_v[e] = v; weights[e] = w
	}
	tree_root := tt_find(mut dsu,0)
	for v in 1 .. n { if tt_find(mut dsu,v) != tree_root { return -1 } }
	mut op_code := []int{len:max_q}; mut op_edge := []int{len:max_q}; mut op_value := []i64{len:max_q}; mut query_count := 0
	for t in 0 .. q {
		off := edge_end+3*t; op := unsafe { input[off] }; edge := unsafe { input[off+1] }; value := unsafe { input[off+2] }
		if op == 0 { if edge < 0 || edge >= n-1 || value < 0 || value > 1000 { return -1 } }
		else if op == 1 { if edge != 0 || value != 0 { return -1 }; query_count++ }
		else { return -1 }
		op_code[t] = int(op); op_edge[t] = int(edge); op_value[t] = value
	}
	output_bytes := 8*query_count
	if output_bytes > 0 && (unsafe { output == nil } || capacity < usize(output_bytes)) { return -2 }
	mut nodes := []Cluster{len:max_nodes}; mut node_count := 0
	mut base_rake := []int{len:max_n}; mut base_edge := []int{len:max_e}
	mut adj := []bool{len:max_n*max_n}; mut active := []bool{len:max_n}
	mut edge_cluster := []int{len:max_n*max_n, init:-1}
	mut branches := []int{len:max_n*max_n}; mut branch_count := []int{len:max_n}
	for v in 0 .. n { active[v] = true; base_rake[v] = tt_append(mut nodes,mut node_count,rake_zero,weights,-1,-1,-1,-1,-1,-1,-1); if base_rake[v] < 0 { return -1 } }
	for e in 0 .. n-1 {
		u := edge_u[e]; v := edge_v[e]; cluster := tt_append(mut nodes,mut node_count,edge_base,weights,-1,-1,-1,u,v,-1,e)
		if cluster < 0 { return -1 }; base_edge[e] = cluster; adj[u*max_n+v] = true; adj[v*max_n+u] = true; edge_cluster[u*max_n+v] = cluster; edge_cluster[v*max_n+u] = cluster
	}
	mut active_count := n
	for active_count > 1 {
		if active_count == 2 {
			mut pair := []int{len:2}; mut found := 0
			for v in 0 .. n { if active[v] { pair[found] = v; found++ } }
			x := pair[0]; y := pair[1]; local := tt_make_rake(mut nodes,mut node_count,weights,base_rake[x],branches[x*max_n..(x+1)*max_n],branch_count[x])
			if local < 0 { return -1 }; branch := tt_append(mut nodes,mut node_count,rake_branch,weights,edge_cluster[x*max_n+y],local,-1,y,-1,x,-1)
			if branch < 0 || branch_count[y] >= max_n { return -1 }; branches[y*max_n+branch_count[y]] = branch; branch_count[y]++
			adj[x*max_n+y] = false; adj[y*max_n+x] = false; edge_cluster[x*max_n+y] = -1; edge_cluster[y*max_n+x] = -1; active[x] = false; active_count--; break
		}
		mut leaves := []int{len:max_n}; mut leaf_neighbor := []int{len:max_n}; mut leaf_count := 0
		for v in 0 .. n { if active[v] { mut a := []int{len:2}; if tt_neighbors(adj,active,n,v,mut a) == 1 { leaves[leaf_count] = v; leaf_neighbor[leaf_count] = a[0]; leaf_count++ } } }
		for i in 0 .. leaf_count {
			x := leaves[i]; y := leaf_neighbor[i]; local := tt_make_rake(mut nodes,mut node_count,weights,base_rake[x],branches[x*max_n..(x+1)*max_n],branch_count[x])
			if local < 0 { return -1 }; branch := tt_append(mut nodes,mut node_count,rake_branch,weights,edge_cluster[x*max_n+y],local,-1,y,-1,x,-1)
			if branch < 0 || branch_count[y] >= max_n { return -1 }; branches[y*max_n+branch_count[y]] = branch; branch_count[y]++
		}
		for i in 0 .. leaf_count { x := leaves[i]; y := leaf_neighbor[i]; adj[x*max_n+y] = false; adj[y*max_n+x] = false; edge_cluster[x*max_n+y] = -1; edge_cluster[y*max_n+x] = -1; active[x] = false; active_count-- }
		if active_count <= 1 { break }
		mut chosen := []bool{len:max_n}; mut cv := []int{len:max_n}; mut cc := 0
		for x in 0 .. n { if active[x] { mut a := []int{len:2}; if tt_neighbors(adj,active,n,x,mut a) != 2 { continue }; if !chosen[a[0]] && !chosen[a[1]] { chosen[x] = true; cv[cc] = x; cc++ } } }
		mut px := []int{len:max_n}; mut py := []int{len:max_n}; mut pz := []int{len:max_n}; mut pc := []int{len:max_n}
		for i in 0 .. cc {
			x := cv[i]; mut a := []int{len:2}; _ = tt_neighbors(adj,active,n,x,mut a); y := a[0]; z := a[1]
			local := tt_make_rake(mut nodes,mut node_count,weights,base_rake[x],branches[x*max_n..(x+1)*max_n],branch_count[x]); if local < 0 { return -1 }
			cluster := tt_append(mut nodes,mut node_count,edge_compress,weights,edge_cluster[y*max_n+x],edge_cluster[x*max_n+z],local,y,z,x,-1); if cluster < 0 { return -1 }
			px[i] = x; py[i] = y; pz[i] = z; pc[i] = cluster
		}
		for i in 0 .. cc { x := px[i]; y := py[i]; z := pz[i]; adj[y*max_n+x] = false; adj[x*max_n+y] = false; adj[x*max_n+z] = false; adj[z*max_n+x] = false; edge_cluster[y*max_n+x] = -1; edge_cluster[x*max_n+y] = -1; edge_cluster[x*max_n+z] = -1; edge_cluster[z*max_n+x] = -1; active[x] = false; active_count-- }
		for i in 0 .. cc { y := py[i]; z := pz[i]; adj[y*max_n+z] = true; adj[z*max_n+y] = true; edge_cluster[y*max_n+z] = pc[i]; edge_cluster[z*max_n+y] = pc[i] }
	}
	mut root_vertex := 0; for !active[root_vertex] { root_vertex++ }
	root := tt_make_rake(mut nodes,mut node_count,weights,base_rake[root_vertex],branches[root_vertex*max_n..(root_vertex+1)*max_n],branch_count[root_vertex]); if root < 0 { return -1 }
	mut staged := []i64{len:max_q}; mut staged_count := 0
	for t in 0 .. q {
		if op_code[t] == 0 { e := op_edge[t]; weights[e] = op_value[t]; mut node := base_edge[e]; tt_recalc(mut nodes,node,weights); mut ancestor := nodes[node].parent; for ancestor >= 0 { node = ancestor; tt_recalc(mut nodes,node,weights); ancestor = nodes[node].parent } }
		else { staged[staged_count] = nodes[root].diameter; staged_count++ }
	}
	for i in 0 .. staged_count { tt_store(mut output,i*8,staged[i]) }
	return i64(output_bytes)
}
