module point_set_tree_path_composite_sum

const max_n = 16
const max_q = 32
const max_e = 15
const max_nodes = 75
const max_input = 238
const modulus = i64(998244353)
const vertex_kind = 0
const edge_kind = 1
const rake_kind = 2
const branch_kind = 3
const attach_kind = 4
const compress_kind = 5

struct Affine {
	mul i64
	add i64
}
struct Cluster {
mut:
	kind int
	a int
	b int
	parent int
	shared int
	boundary0 int
	boundary1 int
	boundary_count int
	edge int
	has0 bool
	has1 bool
	mask u16
	count int
	sum0 i64
	sum1 i64
	forward Affine
	reverse Affine
}
struct Context {
	sum0 i64
	count0 i64
	sum1 i64
	count1 i64
}
struct SumCount {
	sum i64
	count i64
}

fn norm(value i64) i64 {
	mut out := value % modulus
	if out < 0 { out += modulus }
	return out
}
fn identity() Affine { return Affine{1, 0} }
fn compose(outer Affine, inner Affine) Affine {
	return Affine{outer.mul * inner.mul % modulus, (outer.mul * inner.add + outer.add) % modulus}
}
fn apply_map(map Affine, sum i64, count i64) i64 {
	return (map.mul * sum + map.add * count) % modulus
}
fn boundary_index(node Cluster, vertex int) int {
	if node.boundary0 == vertex { return 0 }
	if node.boundary_count == 2 && node.boundary1 == vertex { return 1 }
	return -1
}
fn has_vertex(node Cluster, vertex int) bool {
	index := boundary_index(node, vertex)
	if index == 0 { return node.has0 }
	if index == 1 { return node.has1 }
	return false
}
fn sum_at(node Cluster, vertex int) i64 {
	if boundary_index(node, vertex) == 0 { return node.sum0 }
	return node.sum1
}
fn map_at(node Cluster, from int, to int) Affine {
	if from == to || node.boundary_count != 2 { return identity() }
	if node.boundary0 == from && node.boundary1 == to { return node.forward }
	return node.reverse
}
fn recalc(mut nodes []Cluster, id int, values []i64, edges []Affine) {
	x := nodes[id]
	if x.kind == vertex_kind {
		nodes[id].count = 1
		nodes[id].mask = u16(1 << x.boundary0)
		nodes[id].sum0 = values[x.boundary0]
		nodes[id].has0 = true
		return
	}
	if x.kind == edge_kind {
		nodes[id].forward = edges[x.edge]
		nodes[id].reverse = edges[x.edge]
		return
	}
	a := nodes[x.a]
	b := nodes[x.b]
	overlap := has_vertex(a, x.shared) && has_vertex(b, x.shared)
	mut removed := 0
	mut duplicate := i64(0)
	if overlap { removed = 1; duplicate = values[x.shared] }
	nodes[id].count = a.count + b.count - removed
	nodes[id].mask = a.mask | b.mask
	for index, boundary in [x.boundary0, x.boundary1] {
		if index >= x.boundary_count { break }
		mut total := i64(0)
		if boundary == x.shared {
			total = norm(sum_at(a, x.shared) + sum_at(b, x.shared) - duplicate)
		} else if boundary_index(a, boundary) >= 0 {
			sibling := norm(sum_at(b, x.shared) - duplicate)
			total = (sum_at(a, boundary) + apply_map(map_at(a, boundary, x.shared), sibling, i64(b.count-removed))) % modulus
		} else {
			sibling := norm(sum_at(a, x.shared) - duplicate)
			total = (sum_at(b, boundary) + apply_map(map_at(b, boundary, x.shared), sibling, i64(a.count-removed))) % modulus
		}
		boundary_has := has_vertex(a, boundary) || has_vertex(b, boundary)
		if index == 0 { nodes[id].sum0 = total; nodes[id].has0 = boundary_has }
		else { nodes[id].sum1 = total; nodes[id].has1 = boundary_has }
	}
	if x.boundary_count == 2 {
		u := x.boundary0
		v := x.boundary1
		au := boundary_index(a, u) >= 0
		av := boundary_index(a, v) >= 0
		bu := boundary_index(b, u) >= 0
		bv := boundary_index(b, v) >= 0
		if au && av {
			nodes[id].forward = map_at(a, u, v); nodes[id].reverse = map_at(a, v, u)
		} else if bu && bv {
			nodes[id].forward = map_at(b, u, v); nodes[id].reverse = map_at(b, v, u)
		} else {
			nodes[id].forward = compose(map_at(a, u, x.shared), map_at(b, x.shared, v))
			nodes[id].reverse = compose(map_at(b, v, x.shared), map_at(a, x.shared, u))
		}
	}
}
fn append_cluster(mut nodes []Cluster, mut used int, kind int, a_id int, b_id int, shared int,
	values []i64, edges []Affine) int {
	if used >= max_nodes { return -1 }
	id := used
	used++
	nodes[id] = Cluster{kind: kind, a: a_id, b: b_id, parent: -1, shared: shared,
		edge: -1, forward: identity(), reverse: identity()}
	if kind == vertex_kind {
		nodes[id].boundary0 = shared; nodes[id].boundary_count = 1
	} else if kind == edge_kind {
		nodes[id].boundary0 = a_id; nodes[id].boundary1 = b_id
		nodes[id].boundary_count = 2; nodes[id].edge = shared
	} else {
		a := nodes[a_id]; b := nodes[b_id]
		a_other := a.boundary0
		if a.boundary_count == 2 && a.boundary0 == shared { a_other = a.boundary1 }
		b_other := b.boundary0
		if b.boundary_count == 2 && b.boundary0 == shared { b_other = b.boundary1 }
		if kind == rake_kind { nodes[id].boundary0 = shared; nodes[id].boundary_count = 1 }
		else if kind == branch_kind { nodes[id].boundary0 = a_other; nodes[id].boundary_count = 1 }
		else if kind == attach_kind { nodes[id].boundary0 = a.boundary0; nodes[id].boundary1 = a.boundary1; nodes[id].boundary_count = 2 }
		else { nodes[id].boundary0 = a_other; nodes[id].boundary1 = b_other; nodes[id].boundary_count = 2 }
		nodes[a_id].parent = id; nodes[b_id].parent = id
	}
	recalc(mut nodes, id, values, edges)
	return id
}
fn make_rake(mut nodes []Cluster, mut used int, base int, branches []int, branch_count int,
	values []i64, edges []Affine) int {
	mut level := []int{len: max_n + 1}; mut next := []int{len: max_n + 1}
	mut count := 1; level[0] = base
	for i in 0 .. branch_count { level[count] = branches[i]; count++ }
	for count > 1 {
		mut next_count := 0; mut i := 0
		for i < count {
			if i+1 == count { next[next_count] = level[i]; next_count++ }
			else {
				shared := nodes[level[i]].boundary0
				merged := append_cluster(mut nodes, mut used, rake_kind, level[i], level[i+1], shared, values, edges)
				if merged < 0 { return -1 }
				next[next_count] = merged; next_count++
			}
			i += 2
		}
		for j in 0 .. next_count { level[j] = next[j] }
		count = next_count
	}
	return level[0]
}
fn neighbor_count(adj []bool, active []bool, n int, vertex int, mut output []int) int {
	mut count := 0
	for other in 0 .. n {
		if active[other] && adj[vertex*max_n+other] { if count < 2 { output[count] = other }; count++ }
	}
	return count
}
fn find_root(mut parent []int, vertex int) int {
	mut v := vertex
	for parent[v] != v { parent[v] = parent[parent[v]]; v = parent[v] }
	return v
}
fn context_at(node Cluster, context Context, vertex int) SumCount {
	index := boundary_index(node, vertex)
	if index == 0 { return SumCount{context.sum0, context.count0} }
	if index == 1 { return SumCount{context.sum1, context.count1} }
	return SumCount{0, 0}
}
fn child_context(nodes []Cluster, parent_id int, child_id int, context Context, values []i64) Context {
	parent := nodes[parent_id]
	child := nodes[child_id]
	sibling_id := if child_id == parent.a { parent.b } else { parent.a }
	sibling := nodes[sibling_id]
	x := parent.shared
	overlap := has_vertex(child, x) && has_vertex(sibling, x)
	mut count_x := i64(sibling.count)
	mut sum_x := norm(sum_at(sibling, x))
	if overlap { count_x--; sum_x = norm(sum_x - values[x]) }
	for boundary in [sibling.boundary0, sibling.boundary1] {
		if boundary_index(parent, boundary) < 0 { continue }
		outside := context_at(parent, context, boundary)
		sum_x = (sum_x + apply_map(map_at(sibling, x, boundary), outside.sum, outside.count)) % modulus
		count_x += outside.count
	}
	mut result := Context{}
	for i, boundary in [child.boundary0, child.boundary1] {
		if i >= child.boundary_count { break }
		mut sum := sum_x
		mut count := count_x
		if boundary != x { sum = apply_map(map_at(child, boundary, x), sum_x, count_x) }
		if boundary != x && boundary_index(parent, boundary) >= 0 {
			outside := context_at(parent, context, boundary)
			sum = (sum + outside.sum) % modulus
			count += outside.count
		}
		if i == 0 { result.sum0 = sum; result.count0 = count }
		else { result.sum1 = sum; result.count1 = count }
	}
	return result
}
fn query(nodes []Cluster, root int, vertex_leaf []int, vertex int, values []i64) i64 {
	mut path := []int{len: max_nodes}
	mut len := 1
	path[0] = vertex_leaf[vertex]
	for path[len-1] != root && len < max_nodes {
		parent := nodes[path[len-1]].parent
		if parent < 0 { return -1 }
		path[len] = parent; len++
	}
	if path[len-1] != root { return -1 }
	mut context := Context{}
	mut i := len - 1
	for i > 0 { context = child_context(nodes, path[i], path[i-1], context, values); i-- }
	return (nodes[vertex_leaf[vertex]].sum0 + context.sum0) % modulus
}
fn store_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[offset+byte] = u8(bits >> (8*byte)) } }
}
fn read_word(input &i64, index int) i64 { return unsafe { input[index] } }

@[export: 'point_set_tree_path_composite_sum']
pub fn point_set_tree_path_composite_sum(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(max_input) { return -1 }
	nr := read_word(input, 0); qr := read_word(input, 1)
	if nr < 1 || nr > max_n || qr < 1 || qr > max_q { return -1 }
	n := int(nr); q := int(qr); mut cursor := 2
	mut values := []i64{len: max_n}
	for v in 0 .. n { if cursor >= int(length) { return -1 }; values[v] = read_word(input,cursor); cursor++; if values[v] < 0 || values[v] >= modulus { return -1 } }
	mut edge_u := []int{len:max_e}; mut edge_v := []int{len:max_e}; mut edges := []Affine{len:max_e}
	mut dsu := []int{len:max_n}; for v in 0 .. n { dsu[v] = v }
	for e in 0 .. n-1 {
		if cursor+4 > int(length) { return -1 }
		ur:=read_word(input,cursor);vr:=read_word(input,cursor+1);mul:=read_word(input,cursor+2);add:=read_word(input,cursor+3);cursor+=4
		if ur<0||ur>=nr||vr<0||vr>=nr||ur==vr||mul<1||mul>=modulus||add<0||add>=modulus{return -1}
		u:=int(ur);v:=int(vr);ru:=find_root(mut dsu,u);rv:=find_root(mut dsu,v);if ru==rv{return -1};dsu[ru]=rv;edge_u[e]=u;edge_v[e]=v;edges[e]=Affine{mul,add}
	}
	tree_root:=find_root(mut dsu,0);for v in 1 .. n {if find_root(mut dsu,v)!=tree_root{return -1}}
	mut op_code:=[]int{len:max_q};mut op_item:=[]int{len:max_q};mut op_first:=[]i64{len:max_q};mut op_second:=[]i64{len:max_q};mut op_root:=[]int{len:max_q}
	for i in 0 .. q {
		if cursor>=int(length){return -1};opcode:=read_word(input,cursor);cursor++
		if opcode==0 {if cursor+3>int(length){return -1};item:=read_word(input,cursor);value:=read_word(input,cursor+1);root:=read_word(input,cursor+2);cursor+=3;if item<0||item>=nr||value<0||value>=modulus||root<0||root>=nr{return -1};op_code[i]=0;op_item[i]=int(item);op_first[i]=value;op_root[i]=int(root)}
		else if opcode==1 {if cursor+4>int(length){return -1};item:=read_word(input,cursor);mul:=read_word(input,cursor+1);add:=read_word(input,cursor+2);root:=read_word(input,cursor+3);cursor+=4;if item<0||item>=nr-1||mul<1||mul>=modulus||add<0||add>=modulus||root<0||root>=nr{return -1};op_code[i]=1;op_item[i]=int(item);op_first[i]=mul;op_second[i]=add;op_root[i]=int(root)}
		else{return -1}
	}
	if cursor!=int(length){return -1};required:=8*q;if unsafe{output==nil}||capacity<usize(required){return -2}
	mut nodes:=[]Cluster{len:max_nodes};mut used:=0;mut vertex_leaf:=[]int{len:max_n};mut edge_leaf:=[]int{len:max_e}
	for v in 0 .. n {id:=append_cluster(mut nodes,mut used,vertex_kind,-1,-1,v,values,edges);if id<0{return -1};vertex_leaf[v]=id}
	mut adj:=[]bool{len:max_n*max_n};mut edge_cluster:=[]int{len:max_n*max_n,init:-1}
	for e in 0 .. n-1 {id:=append_cluster(mut nodes,mut used,edge_kind,edge_u[e],edge_v[e],e,values,edges);if id<0{return -1};edge_leaf[e]=id;u:=edge_u[e];v:=edge_v[e];adj[u*max_n+v]=true;adj[v*max_n+u]=true;edge_cluster[u*max_n+v]=id;edge_cluster[v*max_n+u]=id}
	mut active:=[]bool{len:max_n};mut branches:=[]int{len:max_n*max_n};mut branch_count:=[]int{len:max_n};for v in 0 .. n {active[v]=true};mut active_count:=n
	for active_count>1 {
		if active_count==2 {mut pair:=[]int{len:2};mut found:=0;for v in 0 .. n {if active[v]{pair[found]=v;found++}};x:=pair[0];y:=pair[1];local:=make_rake(mut nodes,mut used,vertex_leaf[x],branches[x*max_n..(x+1)*max_n],branch_count[x],values,edges);if local<0{return -1};branch:=append_cluster(mut nodes,mut used,branch_kind,edge_cluster[x*max_n+y],local,x,values,edges);if branch<0||branch_count[y]>=max_n{return -1};branches[y*max_n+branch_count[y]]=branch;branch_count[y]++;adj[x*max_n+y]=false;adj[y*max_n+x]=false;edge_cluster[x*max_n+y]=-1;edge_cluster[y*max_n+x]=-1;active[x]=false;active_count--;break}
		mut leaves:=[]int{len:max_n};mut leaf_neighbor:=[]int{len:max_n};mut leaf_count:=0
		for v in 0 .. n {if active[v]{mut near:=[]int{len:2};if neighbor_count(adj,active,n,v,mut near)==1{leaves[leaf_count]=v;leaf_neighbor[leaf_count]=near[0];leaf_count++}}}
		for i in 0 .. leaf_count {x:=leaves[i];y:=leaf_neighbor[i];local:=make_rake(mut nodes,mut used,vertex_leaf[x],branches[x*max_n..(x+1)*max_n],branch_count[x],values,edges);if local<0{return -1};branch:=append_cluster(mut nodes,mut used,branch_kind,edge_cluster[x*max_n+y],local,x,values,edges);if branch<0||branch_count[y]>=max_n{return -1};branches[y*max_n+branch_count[y]]=branch;branch_count[y]++}
		for i in 0 .. leaf_count {x:=leaves[i];y:=leaf_neighbor[i];adj[x*max_n+y]=false;adj[y*max_n+x]=false;edge_cluster[x*max_n+y]=-1;edge_cluster[y*max_n+x]=-1;active[x]=false;active_count--}
		if active_count<=1{break};mut chosen:=[]bool{len:max_n};mut compress:=[]int{len:max_n};mut cc:=0
		for x in 0 .. n {if active[x]{mut near:=[]int{len:2};if neighbor_count(adj,active,n,x,mut near)!=2{continue};if !chosen[near[0]]&&!chosen[near[1]]{chosen[x]=true;compress[cc]=x;cc++}}}
		mut px:=[]int{len:max_n};mut py:=[]int{len:max_n};mut pz:=[]int{len:max_n};mut pc:=[]int{len:max_n}
		for i in 0 .. cc {x:=compress[i];mut near:=[]int{len:2};_=neighbor_count(adj,active,n,x,mut near);y:=near[0];z:=near[1];local:=make_rake(mut nodes,mut used,vertex_leaf[x],branches[x*max_n..(x+1)*max_n],branch_count[x],values,edges);if local<0{return -1};attached:=append_cluster(mut nodes,mut used,attach_kind,edge_cluster[y*max_n+x],local,x,values,edges);if attached<0{return -1};merged:=append_cluster(mut nodes,mut used,compress_kind,attached,edge_cluster[x*max_n+z],x,values,edges);if merged<0{return -1};px[i]=x;py[i]=y;pz[i]=z;pc[i]=merged}
		for i in 0 .. cc {x:=px[i];y:=py[i];z:=pz[i];adj[y*max_n+x]=false;adj[x*max_n+y]=false;adj[x*max_n+z]=false;adj[z*max_n+x]=false;edge_cluster[y*max_n+x]=-1;edge_cluster[x*max_n+y]=-1;edge_cluster[x*max_n+z]=-1;edge_cluster[z*max_n+x]=-1;active[x]=false;active_count--}
		for i in 0 .. cc {y:=py[i];z:=pz[i];adj[y*max_n+z]=true;adj[z*max_n+y]=true;edge_cluster[y*max_n+z]=pc[i];edge_cluster[z*max_n+y]=pc[i]}
	}
	mut root_vertex:=0;for !active[root_vertex]{root_vertex++};root:=make_rake(mut nodes,mut used,vertex_leaf[root_vertex],branches[root_vertex*max_n..(root_vertex+1)*max_n],branch_count[root_vertex],values,edges);if root<0{return -1}
	mut answers:=[]i64{len:max_q};for i in 0 .. q {item:=op_item[i];mut node_id:=0;if op_code[i]==0{values[item]=op_first[i];node_id=vertex_leaf[item];recalc(mut nodes,node_id,values,edges)}else{edges[item]=Affine{op_first[i],op_second[i]};node_id=edge_leaf[item];recalc(mut nodes,node_id,values,edges)};mut ancestor:=nodes[node_id].parent;for ancestor>=0{recalc(mut nodes,ancestor,values,edges);ancestor=nodes[ancestor].parent};answers[i]=query(nodes,root,vertex_leaf,op_root[i],values);if answers[i]<0{return -1}}
	for i in 0 .. q {store_le(mut output,8*i,answers[i])};return i64(required)
}
