package dynamic_top_tree_component_diameter

import "core:c"

MAX_N :: 16
MAX_Q :: 32
MAX_E :: 15
MAX_NODES :: 75
MAX_INPUT :: 143
EDGE_BASE :: 0
EDGE_COMPRESS :: 1
RAKE_ZERO :: 2
RAKE_MERGE :: 3
RAKE_BRANCH :: 4

Cluster :: struct {
	kind, a, b, c, parent, end0, end1, pivot, edge: int,
	length, far0, far1, diameter, best1, best2: i64,
}

far_at :: proc "contextless" (nodes: [^]Cluster, id, vertex: int) -> i64 {
	if nodes[id].end0 == vertex do return nodes[id].far0
	return nodes[id].far1
}

recalculate :: proc "contextless" (nodes: [^]Cluster, id: int, weights: [^]i64) {
	x := nodes[id]
	if x.kind == EDGE_BASE {
		w := weights[x.edge]
		nodes[id].length = w; nodes[id].far0 = w; nodes[id].far1 = w; nodes[id].diameter = w
	} else if x.kind == RAKE_ZERO {
		nodes[id].best1 = 0; nodes[id].best2 = 0; nodes[id].diameter = 0
	} else if x.kind == RAKE_MERGE {
		l := nodes[x.a]; r := nodes[x.b]
		first: i64 = 0; second: i64 = 0
		arms := [4]i64{l.best1,l.best2,r.best1,r.best2}
		for arm in arms {
			if arm >= first { second = first; first = arm }
			else if arm > second { second = arm }
		}
		nodes[id].best1 = first; nodes[id].best2 = second
		nodes[id].diameter = max(l.diameter, max(r.diameter, l.best1+r.best1))
	} else if x.kind == RAKE_BRANCH {
		e := nodes[x.a]; local := nodes[x.b]
		center := far_at(nodes,x.a,x.end0); pivot_far := far_at(nodes,x.a,x.pivot)
		nodes[id].best1 = max(center,e.length+local.best1); nodes[id].best2 = 0
		nodes[id].diameter = max(e.diameter,max(local.diameter,pivot_far+local.best1))
	} else {
		a := nodes[x.a]; b := nodes[x.b]; local := nodes[x.c]
		ay := far_at(nodes,x.a,x.end0); ap := far_at(nodes,x.a,x.pivot)
		bp := far_at(nodes,x.b,x.pivot); bz := far_at(nodes,x.b,x.end1)
		nodes[id].length = a.length+b.length
		nodes[id].far0 = max(ay,a.length+max(bp,local.best1))
		nodes[id].far1 = max(bz,b.length+max(ap,local.best1))
		nodes[id].diameter = max(a.diameter,max(b.diameter,max(local.diameter,max(ap+bp,max(ap+local.best1,bp+local.best1)))))
	}
}

append_cluster :: proc "contextless" (nodes: [^]Cluster, count: ^int, kind: int, weights: [^]i64,
	a,b,c_node,end0,end1,pivot,edge: int) -> int {
	if count^ >= MAX_NODES do return -1
	id := count^; count^ += 1
	nodes[id] = Cluster{kind,a,b,c_node,-1,end0,end1,pivot,edge,0,0,0,0,0,0}
	if a >= 0 { nodes[a].parent = id }
	if b >= 0 { nodes[b].parent = id }
	if c_node >= 0 { nodes[c_node].parent = id }
	recalculate(nodes,id,weights)
	return id
}

make_rake :: proc "contextless" (nodes: [^]Cluster,count: ^int,weights: [^]i64,base: int,
	branches: [^]int,branch_count: int) -> int {
	level: [MAX_N+1]int; next: [MAX_N+1]int
	len := 1; level[0] = base
	for i := 0; i < branch_count; i += 1 { level[len] = branches[i]; len += 1 }
	for len > 1 {
		next_len := 0
		for i := 0; i < len; i += 2 {
			if i+1 == len { next[next_len] = level[i]; next_len += 1 }
			else {
				merged := append_cluster(nodes,count,RAKE_MERGE,weights,level[i],level[i+1],-1,-1,-1,-1,-1)
				if merged < 0 do return -1
				next[next_len] = merged; next_len += 1
			}
		}
		for i := 0; i < next_len; i += 1 { level[i] = next[i] }
		len = next_len
	}
	return level[0]
}

neighbor_count :: proc "contextless" (adj: [^]bool, active: [^]bool,n,vertex:int,out:[^]int) -> int {
	count := 0
	for other := 0; other < n; other += 1 {
		if active[other] && adj[vertex*MAX_N+other] { if count < 2 { out[count] = other }; count += 1 }
	}
	return count
}

find_root :: proc "contextless" (parent: [^]int, vertex: int) -> int {
	v := vertex
	for parent[v] != v { parent[v] = parent[parent[v]]; v = parent[v] }
	return v
}

store_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(8*byte)) }
}

@(export)
dynamic_top_tree_component_diameter :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	nv := input[0]; qv := input[1]
	if nv < 1 || nv > MAX_N || qv < 0 || qv > MAX_Q do return -1
	n := int(nv); q := int(qv); edge_end := 2+3*(n-1)
	if length != c.size_t(edge_end+3*q) do return -1
	edge_u: [MAX_E]int; edge_v: [MAX_E]int; dsu: [MAX_N]int; weights: [MAX_E]i64
	for v := 0; v < n; v += 1 { dsu[v] = v }
	for e := 0; e < n-1; e += 1 {
		off := 2+3*e; uv := input[off]; vv := input[off+1]; w := input[off+2]
		if uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv || w < 0 || w > 1000 do return -1
		u := int(uv); v := int(vv); ru := find_root(&dsu[0],u); rv := find_root(&dsu[0],v)
		if ru == rv do return -1
		dsu[ru] = rv; edge_u[e] = u; edge_v[e] = v; weights[e] = w
	}
	tree_root := find_root(&dsu[0],0)
	for v := 1; v < n; v += 1 { if find_root(&dsu[0],v) != tree_root do return -1 }
	op_code: [MAX_Q]int; op_edge: [MAX_Q]int; op_value: [MAX_Q]i64; query_count := 0
	for t := 0; t < q; t += 1 {
		off := edge_end+3*t; op := input[off]; edge := input[off+1]; value := input[off+2]
		if op == 0 { if edge < 0 || edge >= n-1 || value < 0 || value > 1000 do return -1 }
		else if op == 1 { if edge != 0 || value != 0 do return -1; query_count += 1 }
		else { return -1 }
		op_code[t] = int(op); op_edge[t] = int(edge); op_value[t] = value
	}
	output_bytes := 8*query_count
	if output_bytes > 0 && (output == nil || capacity < c.size_t(output_bytes)) do return -2

	nodes: [MAX_NODES]Cluster; node_count := 0
	base_rake: [MAX_N]int; base_edge: [MAX_E]int
	adj: [MAX_N*MAX_N]bool; active: [MAX_N]bool
	edge_cluster: [MAX_N*MAX_N]int; branches: [MAX_N*MAX_N]int; branch_count: [MAX_N]int
	for i := 0; i < MAX_N*MAX_N; i += 1 { edge_cluster[i] = -1 }
	for v := 0; v < n; v += 1 { active[v] = true; base_rake[v] = append_cluster(&nodes[0],&node_count,RAKE_ZERO,&weights[0],-1,-1,-1,-1,-1,-1,-1); if base_rake[v] < 0 do return -1 }
	for e := 0; e < n-1; e += 1 {
		u := edge_u[e]; v := edge_v[e]
		cluster := append_cluster(&nodes[0],&node_count,EDGE_BASE,&weights[0],-1,-1,-1,u,v,-1,e)
		if cluster < 0 do return -1
		base_edge[e] = cluster; adj[u*MAX_N+v] = true; adj[v*MAX_N+u] = true
		edge_cluster[u*MAX_N+v] = cluster; edge_cluster[v*MAX_N+u] = cluster
	}
	active_count := n
	for active_count > 1 {
		if active_count == 2 {
			pair: [2]int; found := 0
			for v := 0; v < n; v += 1 { if active[v] { pair[found] = v; found += 1 } }
			x := pair[0]; y := pair[1]
			local := make_rake(&nodes[0],&node_count,&weights[0],base_rake[x],&branches[x*MAX_N],branch_count[x])
			if local < 0 do return -1
			branch := append_cluster(&nodes[0],&node_count,RAKE_BRANCH,&weights[0],edge_cluster[x*MAX_N+y],local,-1,y,-1,x,-1)
			if branch < 0 || branch_count[y] >= MAX_N do return -1
			branches[y*MAX_N+branch_count[y]] = branch; branch_count[y] += 1
			adj[x*MAX_N+y] = false; adj[y*MAX_N+x] = false; edge_cluster[x*MAX_N+y] = -1; edge_cluster[y*MAX_N+x] = -1
			active[x] = false; active_count -= 1; break
		}
		leaves: [MAX_N]int; leaf_neighbor: [MAX_N]int; leaf_count := 0
		for v := 0; v < n; v += 1 { if active[v] { adjacent: [2]int; if neighbor_count(&adj[0],&active[0],n,v,&adjacent[0]) == 1 { leaves[leaf_count] = v; leaf_neighbor[leaf_count] = adjacent[0]; leaf_count += 1 } } }
		for i := 0; i < leaf_count; i += 1 {
			x := leaves[i]; y := leaf_neighbor[i]
			local := make_rake(&nodes[0],&node_count,&weights[0],base_rake[x],&branches[x*MAX_N],branch_count[x])
			if local < 0 do return -1
			branch := append_cluster(&nodes[0],&node_count,RAKE_BRANCH,&weights[0],edge_cluster[x*MAX_N+y],local,-1,y,-1,x,-1)
			if branch < 0 || branch_count[y] >= MAX_N do return -1
			branches[y*MAX_N+branch_count[y]] = branch; branch_count[y] += 1
		}
		for i := 0; i < leaf_count; i += 1 { x := leaves[i]; y := leaf_neighbor[i]; adj[x*MAX_N+y] = false; adj[y*MAX_N+x] = false; edge_cluster[x*MAX_N+y] = -1; edge_cluster[y*MAX_N+x] = -1; active[x] = false; active_count -= 1 }
		if active_count <= 1 do break
		chosen: [MAX_N]bool; cv: [MAX_N]int; cc := 0
		for x := 0; x < n; x += 1 { if active[x] { adjacent: [2]int; if neighbor_count(&adj[0],&active[0],n,x,&adjacent[0]) != 2 do continue; if !chosen[adjacent[0]] && !chosen[adjacent[1]] { chosen[x] = true; cv[cc] = x; cc += 1 } } }
		px: [MAX_N]int; py: [MAX_N]int; pz: [MAX_N]int; pc: [MAX_N]int
		for i := 0; i < cc; i += 1 {
			x := cv[i]; adjacent: [2]int; _ = neighbor_count(&adj[0],&active[0],n,x,&adjacent[0]); y := adjacent[0]; z := adjacent[1]
			local := make_rake(&nodes[0],&node_count,&weights[0],base_rake[x],&branches[x*MAX_N],branch_count[x]); if local < 0 do return -1
			cluster := append_cluster(&nodes[0],&node_count,EDGE_COMPRESS,&weights[0],edge_cluster[y*MAX_N+x],edge_cluster[x*MAX_N+z],local,y,z,x,-1); if cluster < 0 do return -1
			px[i] = x; py[i] = y; pz[i] = z; pc[i] = cluster
		}
		for i := 0; i < cc; i += 1 { x := px[i]; y := py[i]; z := pz[i]; adj[y*MAX_N+x] = false; adj[x*MAX_N+y] = false; adj[x*MAX_N+z] = false; adj[z*MAX_N+x] = false; edge_cluster[y*MAX_N+x] = -1; edge_cluster[x*MAX_N+y] = -1; edge_cluster[x*MAX_N+z] = -1; edge_cluster[z*MAX_N+x] = -1; active[x] = false; active_count -= 1 }
		for i := 0; i < cc; i += 1 { y := py[i]; z := pz[i]; adj[y*MAX_N+z] = true; adj[z*MAX_N+y] = true; edge_cluster[y*MAX_N+z] = pc[i]; edge_cluster[z*MAX_N+y] = pc[i] }
	}
	root_vertex := 0; for !active[root_vertex] { root_vertex += 1 }
	root := make_rake(&nodes[0],&node_count,&weights[0],base_rake[root_vertex],&branches[root_vertex*MAX_N],branch_count[root_vertex]); if root < 0 do return -1
	staged: [MAX_Q]i64; staged_count := 0
	for t := 0; t < q; t += 1 {
		if op_code[t] == 0 {
			e := op_edge[t]; weights[e] = op_value[t]; node := base_edge[e]; recalculate(&nodes[0],node,&weights[0]); ancestor := nodes[node].parent
			for ancestor >= 0 { node = ancestor; recalculate(&nodes[0],node,&weights[0]); ancestor = nodes[node].parent }
		} else { staged[staged_count] = nodes[root].diameter; staged_count += 1 }
	}
	for i := 0; i < staged_count; i += 1 { store_le(output,i*8,staged[i]) }
	return i64(output_bytes)
}
