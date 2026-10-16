package yens_kshortest_paths
import "core:c"

Path :: struct { len: int, nodes: [8]i64, cost: i64 }

path_less :: proc(a, b: ^Path) -> bool {
	if a.cost != b.cost do return a.cost < b.cost
	limit := min(a.len, b.len)
	for i in 0..<limit { if a.nodes[i] != b.nodes[i] do return a.nodes[i] < b.nodes[i] }
	return a.len < b.len
}
same_path :: proc(a, b: ^Path) -> bool {
	if a.len != b.len do return false
	for i in 0..<a.len { if a.nodes[i] != b.nodes[i] do return false }
	return true
}
same_prefix :: proc(a, b: ^Path, n: int) -> bool {
	if a.len < n || b.len < n do return false
	for i in 0..<n { if a.nodes[i] != b.nodes[i] do return false }
	return true
}
contains :: proc(path: ^Path, vertex: int) -> bool {
	for i in 0..<path.len { if int(path.nodes[i]) == vertex do return true }
	return false
}
explore_spur :: proc(graph: ^[64]i64, n, dst: int, banned_vertices: ^[8]bool, banned_edges: ^[64]bool, current, best: ^Path, found: ^bool) {
	u := int(current.nodes[current.len-1])
	if u == dst {
		if !found^ || path_less(current,best) { best^=current^; found^=true }
		return
	}
	for v in 0..<n {
		if graph^[u*n+v]<0 || banned_vertices^[v] || banned_edges^[u*8+v] || contains(current,v) do continue
		current.nodes[current.len]=i64(v);current.len+=1;current.cost+=graph^[u*n+v]
		explore_spur(graph,n,dst,banned_vertices,banned_edges,current,best,found)
		current.cost-=graph^[u*n+v];current.len-=1
	}
}
shortest :: proc(graph: ^[64]i64, n, src, dst: int, banned_vertices: ^[8]bool, banned_edges: ^[64]bool, out: ^Path) -> bool {
	current := Path{len=1,nodes=[8]i64{i64(src),0,0,0,0,0,0,0},cost=0}
	found := false
	best: Path
	explore_spur(graph,n,dst,banned_vertices,banned_edges,&current,&best,&found)
	if found { out^=best }
	return found
}
put_i64 :: proc(out: [^]u8, offset: int, value: i64) {
	bits:=u64(value)
	for b in 0..<8 { out[offset+b]=u8((bits >> u64(b*8)) & 255) }
}

@(export)
yens_kshortest_paths :: proc(input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input==nil || length<4 do return -1
	nv,kv,sv,dv:=input[0],input[1],input[2],input[3]
	if nv<1 || nv>8 || kv<1 || kv>8 || sv<0 || sv>=nv || dv<0 || dv>=nv do return -1
	n,k:=int(nv),int(kv)
	if length!=c.size_t(4+n*n) do return -1
	graph: [64]i64
	for i in 0..<n*n { w:=input[4+i];if w < -1 || w>1000 do return -1;graph[i]=w }
	accepted: [8]Path
	candidates: [64]Path
	accepted_count:=0;candidate_count:=0
	banned_vertices: [8]bool
	banned_edges: [64]bool
	first: Path
	if shortest(&graph,n,int(sv),int(dv),&banned_vertices,&banned_edges,&first) { accepted[accepted_count]=first;accepted_count+=1 }
	for accepted_count<k && accepted_count>0 {
		previous:=accepted[accepted_count-1]
		for i in 0..<previous.len-1 {
			root:=Path{len=i+1,cost=0}
			for j in 0..=i { root.nodes[j]=previous.nodes[j] }
			for j in 0..<i { root.cost+=graph[int(root.nodes[j])*n+int(root.nodes[j+1])] }
			for z in 0..<accepted_count { if same_prefix(&accepted[z],&root,i+1) && accepted[z].len>i+1 { banned_edges[int(accepted[z].nodes[i])*8+int(accepted[z].nodes[i+1])]=true } }
			for j in 0..<i { banned_vertices[int(root.nodes[j])]=true }
			spur: Path
			if shortest(&graph,n,int(root.nodes[i]),int(dv),&banned_vertices,&banned_edges,&spur) {
				total:=root
				for j in 1..<spur.len { total.nodes[total.len]=spur.nodes[j];total.len+=1 }
				total.cost+=spur.cost
				found:=false
				for z in 0..<accepted_count { if same_path(&total,&accepted[z]) { found=true } }
				for z in 0..<candidate_count { if same_path(&total,&candidates[z]) { found=true } }
				if !found && candidate_count<64 { candidates[candidate_count]=total;candidate_count+=1 }
			}
			for j in 0..<i { banned_vertices[int(root.nodes[j])]=false }
			for z in 0..<accepted_count { if same_prefix(&accepted[z],&root,i+1) && accepted[z].len>i+1 { banned_edges[int(accepted[z].nodes[i])*8+int(accepted[z].nodes[i+1])]=false } }
		}
		if candidate_count==0 do break
		best:=0
		for i in 1..<candidate_count { if path_less(&candidates[i],&candidates[best]) { best=i } }
		accepted[accepted_count]=candidates[best];accepted_count+=1
		candidate_count-=1
		if best<candidate_count { candidates[best]=candidates[candidate_count] }
	}
	bytes:=8
	for i in 0..<accepted_count { bytes+=(accepted[i].len+2)*8 }
	if output==nil || output_capacity<c.size_t(bytes) do return -2
	put_i64(output,0,i64(accepted_count));at:=8
	for i in 0..<accepted_count { put_i64(output,at,i64(accepted[i].len));at+=8;for j in 0..<accepted[i].len { put_i64(output,at,accepted[i].nodes[j]);at+=8 };put_i64(output,at,accepted[i].cost);at+=8 }
	return i64(bytes)
}
