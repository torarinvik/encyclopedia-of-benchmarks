package point_set_tree_path_composite_sum

import "core:c"

MAX_N :: 16
MAX_Q :: 32
MAX_E :: 15
MAX_CLUSTERS :: 75
MAX_INPUT :: 238
MOD :: i64(998244353)
VERTEX :: 0
EDGE :: 1
RAKE :: 2
BRANCH :: 3
ATTACH :: 4
COMPRESS :: 5

Affine :: struct { mul, add: i64 }
Cluster :: struct {
	kind, a, b, parent, shared, boundary0, boundary1, boundary_count, edge_id: i16,
	has0, has1: bool,
	mask: u16,
	count: i32,
	sum0, sum1: i64,
	forward, reverse: Affine,
}
Context :: struct { sum0, count0, sum1, count1: i64 }

norm :: proc "contextless" (x0: i64) -> i64 {
	x := x0 % MOD
	if x < 0 do x += MOD
	return x
}
identity :: proc "contextless" () -> Affine { return Affine{1, 0} }
compose :: proc "contextless" (outer, inner: Affine) -> Affine {
	return Affine{outer.mul*inner.mul%MOD, (outer.mul*inner.add+outer.add)%MOD}
}
apply_map :: proc "contextless" (map: Affine, sum, count: i64) -> i64 {
	return (map.mul*sum+map.add*count)%MOD
}
boundary_index :: proc "contextless" (node: Cluster, vertex: int) -> int {
	if int(node.boundary0) == vertex do return 0
	if node.boundary_count == 2 && int(node.boundary1) == vertex do return 1
	return -1
}
has_vertex :: proc "contextless" (node: Cluster, vertex: int) -> bool {
	i := boundary_index(node,vertex)
	if i == 0 do return node.has0
	if i == 1 do return node.has1
	return false
}
sum_at :: proc "contextless" (node: Cluster, vertex: int) -> i64 {
	if boundary_index(node,vertex) == 0 do return node.sum0
	return node.sum1
}
map_at :: proc "contextless" (node: Cluster, from, to: int) -> Affine {
	if from == to || node.boundary_count != 2 do return identity()
	if int(node.boundary0) == from && int(node.boundary1) == to do return node.forward
	return node.reverse
}

recalculate :: proc "contextless" (nodes: [^]Cluster, id: int, values: [^]i64, edges: [^]Affine) {
	x := nodes[id]
	if x.kind == VERTEX {
		nodes[id].count = 1; nodes[id].mask = u16(1 << int(x.boundary0))
		nodes[id].sum0 = values[int(x.boundary0)]; nodes[id].has0 = true
		return
	}
	if x.kind == EDGE { nodes[id].forward = edges[int(x.edge_id)]; nodes[id].reverse = edges[int(x.edge_id)]; return }
	a := nodes[int(x.a)]; b := nodes[int(x.b)]; shared := int(x.shared); overlap := has_vertex(a,shared) && has_vertex(b,shared)
	removed := 0; duplicate: i64 = 0
	if overlap { removed = 1; duplicate = values[shared] }
	nodes[id].count = a.count+b.count-i32(removed); nodes[id].mask = a.mask|b.mask
	boundaries := [2]int{int(x.boundary0),int(x.boundary1)}
	for index := 0; index < int(x.boundary_count); index += 1 {
		boundary := boundaries[index]; total: i64
		if boundary == shared { total = norm(sum_at(a,shared)+sum_at(b,shared)-duplicate) }
		else if boundary_index(a,boundary) >= 0 {
			sibling := norm(sum_at(b,shared)-duplicate)
			total = (sum_at(a,boundary)+apply_map(map_at(a,boundary,shared),sibling,i64(b.count-i32(removed))))%MOD
		} else {
			sibling := norm(sum_at(a,shared)-duplicate)
			total = (sum_at(b,boundary)+apply_map(map_at(b,boundary,shared),sibling,i64(a.count-i32(removed))))%MOD
		}
		boundary_has := has_vertex(a,boundary)||has_vertex(b,boundary)
		if index == 0 { nodes[id].sum0=total;nodes[id].has0=boundary_has }
		else { nodes[id].sum1=total;nodes[id].has1=boundary_has }
	}
	if x.boundary_count == 2 {
		u,v := int(x.boundary0),int(x.boundary1)
		au,av := boundary_index(a,u)>=0,boundary_index(a,v)>=0
		bu,bv := boundary_index(b,u)>=0,boundary_index(b,v)>=0
		if au && av { nodes[id].forward=map_at(a,u,v);nodes[id].reverse=map_at(a,v,u) }
		else if bu && bv { nodes[id].forward=map_at(b,u,v);nodes[id].reverse=map_at(b,v,u) }
		else { nodes[id].forward=compose(map_at(a,u,shared),map_at(b,shared,v));nodes[id].reverse=compose(map_at(b,v,shared),map_at(a,shared,u)) }
	}
}

append_cluster :: proc "contextless" (nodes: [^]Cluster, used: ^int, kind, a_id, b_id, shared: int,
	values: [^]i64, edges: [^]Affine) -> int {
	if used^ >= MAX_CLUSTERS do return -1
	id := used^; used^ += 1
	node := &nodes[id]
	node^ = Cluster{kind=i16(kind),a=i16(a_id),b=i16(b_id),parent=-1,shared=i16(shared),edge_id=-1,forward=identity(),reverse=identity()}
	if kind == VERTEX { node.boundary0=i16(shared);node.boundary_count=1 }
	else if kind == EDGE { node.boundary0=i16(a_id);node.boundary1=i16(b_id);node.boundary_count=2;node.edge_id=i16(shared) }
	else {
		a,b := nodes[a_id],nodes[b_id]
		a_other := a.boundary0;if a.boundary_count==2 && int(a.boundary0)==shared { a_other=a.boundary1 }
		b_other := b.boundary0;if b.boundary_count==2 && int(b.boundary0)==shared { b_other=b.boundary1 }
		if kind==RAKE { node.boundary0=i16(shared);node.boundary_count=1 }
		else if kind==BRANCH { node.boundary0=a_other;node.boundary_count=1 }
		else if kind==ATTACH { node.boundary0=a.boundary0;node.boundary1=a.boundary1;node.boundary_count=2 }
		else { node.boundary0=a_other;node.boundary1=b_other;node.boundary_count=2 }
		nodes[a_id].parent=i16(id);nodes[b_id].parent=i16(id)
	}
	recalculate(nodes,id,values,edges)
	return id
}
make_rake :: proc "contextless" (nodes: [^]Cluster, used: ^int, base: int, branches: [^]i16,
	branch_count: int, values: [^]i64, edges: [^]Affine) -> int {
	level,next: [MAX_N+1]int
	count := 1;level[0]=base
	for i:=0;i<branch_count;i+=1 { level[count]=int(branches[i]);count+=1 }
	for count>1 {
		next_count:=0
		for i:=0;i<count;i+=2 {
			if i+1==count { next[next_count]=level[i];next_count+=1 }
			else { shared:=int(nodes[level[i]].boundary0);merged:=append_cluster(nodes,used,RAKE,level[i],level[i+1],shared,values,edges);if merged<0 do return -1;next[next_count]=merged;next_count+=1 }
		}
		for i:=0;i<next_count;i+=1 { level[i]=next[i] }
		count=next_count
	}
	return level[0]
}
neighbor_count :: proc "contextless" (adj: [^]bool,active: [^]bool,n,vertex:int,out:[^]int) -> int {
	count:=0
	for other:=0;other<n;other+=1 { if active[other] && adj[vertex*MAX_N+other] { if count<2 {out[count]=other};count+=1 } }
	return count
}
find_root :: proc "contextless" (parent: [^]int,vertex:int) -> int {
	v:=vertex;for parent[v]!=v { parent[v]=parent[parent[v]];v=parent[v] };return v
}
context_at :: proc "contextless" (node: Cluster,context:Context,vertex:int,out:[^]i64) {
	i:=boundary_index(node,vertex);out[0]=0;out[1]=0
	if i==0 {out[0]=context.sum0;out[1]=context.count0} else if i==1 {out[0]=context.sum1;out[1]=context.count1}
}
child_context :: proc "contextless" (nodes:[^]Cluster,parent_id,child_id:int,context:Context,values:[^]i64) -> Context {
	p:=nodes[parent_id];child:=nodes[child_id];sibling_id:=int(p.a);if child_id==int(p.a) {sibling_id=int(p.b)};sibling:=nodes[sibling_id];x:=int(p.shared)
	overlap:=has_vertex(child,x)&&has_vertex(sibling,x);removed:=0;if overlap {removed=1}
	sum_x:=norm(sum_at(sibling,x));if overlap {sum_x=norm(sum_x-values[x])};count_x:=i64(sibling.count-i32(removed))
	boundaries:=[2]int{int(sibling.boundary0),int(sibling.boundary1)}
	for i:=0;i<int(sibling.boundary_count);i+=1 {boundary:=boundaries[i];if boundary_index(p,boundary)<0 {continue};outside:[2]i64;context_at(p,context,boundary,&outside[0]);sum_x=(sum_x+apply_map(map_at(sibling,x,boundary),outside[0],outside[1]))%MOD;count_x+=outside[1]}
	result:Context
	child_boundaries:=[2]int{int(child.boundary0),int(child.boundary1)}
	for i:=0;i<int(child.boundary_count);i+=1 {boundary:=child_boundaries[i];sum,count:=sum_x,count_x;if boundary!=x {sum=apply_map(map_at(child,boundary,x),sum_x,count_x)};if boundary!=x&&boundary_index(p,boundary)>=0 {outside:[2]i64;context_at(p,context,boundary,&outside[0]);sum=(sum+outside[0])%MOD;count+=outside[1]};if i==0 {result.sum0=sum;result.count0=count}else{result.sum1=sum;result.count1=count}}
	return result
}
query :: proc "contextless" (nodes:[^]Cluster,root:int,vertex_leaf:[^]int,vertex:int,values:[^]i64) -> i64 {
	path:[MAX_CLUSTERS]int;length:=1;path[0]=vertex_leaf[vertex]
	for path[length-1]!=root&&length<MAX_CLUSTERS {parent:=int(nodes[path[length-1]].parent);if parent<0 do return -1;path[length]=parent;length+=1}
	if path[length-1]!=root do return -1
	context:Context
	for i:=length-1;i>0;i-=1 {context=child_context(nodes,path[i],path[i-1],context,values)}
	return (nodes[vertex_leaf[vertex]].sum0+context.sum0)%MOD
}
store_le :: proc "contextless" (output:[^]u8,offset:int,value:i64) {
	bits:=u64(value);for byte:=0;byte<8;byte+=1 {output[offset+byte]=u8((bits>>u64(8*byte))&255)}
}

@(export)
point_set_tree_path_composite_sum :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t) -> i64 {
	if input==nil||length<2||length>MAX_INPUT do return -1
	nr,qr:=input[0],input[1];if nr<1||nr>MAX_N||qr<1||qr>MAX_Q do return -1
	n,q,cur:=int(nr),int(qr),2
	values:[MAX_N]i64
	for v:=0;v<n;v+=1 {if cur>=int(length) do return -1;values[v]=input[cur];cur+=1;if values[v]<0||values[v]>=MOD do return -1}
	eu,ev:[MAX_E]int;edges:[MAX_E]Affine;dsu:[MAX_N]int
	for v:=0;v<n;v+=1 {dsu[v]=v}
	tree_root:=find_root(&dsu[0],0);for v:=1;v<n;v+=1 {if find_root(&dsu[0],v)!=tree_root do return -1}
	opcode:[MAX_Q]int;opitem,oproot:[MAX_Q]int;opfirst,opsecond:[MAX_Q]i64
	for i:=0;i<q;i+=1 {if cur>=int(length) do return -1;op:=input[cur];cur+=1;if op==0 {if cur+3>int(length) do return -1;item,value,root:=input[cur],input[cur+1],input[cur+2];cur+=3;if item<0||item>=nr||value<0||value>=MOD||root<0||root>=nr do return -1;opcode[i],opitem[i],opfirst[i],oproot[i]=0,int(item),value,int(root)}else if op==1 {if cur+4>int(length) do return -1;item,mul,add,root:=input[cur],input[cur+1],input[cur+2],input[cur+3];cur+=4;if item<0||item>=nr-1||mul<1||mul>=MOD||add<0||add>=MOD||root<0||root>=nr do return -1;opcode[i],opitem[i],opfirst[i],opsecond[i],oproot[i]=1,int(item),mul,add,int(root)}else{return -1}}
	if cur!=int(length) do return -1
	bytes:=8*q;if output==nil||capacity<c.size_t(bytes) do return -2
	nodes:[MAX_CLUSTERS]Cluster;used:=0;vertex_leaf:[MAX_N]int;edge_leaf:[MAX_E]int
	for v:=0;v<n;v+=1 {id:=append_cluster(&nodes[0],&used,VERTEX,-1,-1,v,&values[0],&edges[0]);if id<0 do return -1;vertex_leaf[v]=id}
	adj:[MAX_N*MAX_N]bool;edge_cluster:[MAX_N*MAX_N]i16
	for i:=0;i<MAX_N*MAX_N;i+=1 {edge_cluster[i]=-1}
	for e:=0;e<n-1;e+=1 {id:=append_cluster(&nodes[0],&used,EDGE,eu[e],ev[e],e,&values[0],&edges[0]);if id<0 do return -1;edge_leaf[e]=id;adj[eu[e]*MAX_N+ev[e]]=true;adj[ev[e]*MAX_N+eu[e]]=true;edge_cluster[eu[e]*MAX_N+ev[e]]=i16(id);edge_cluster[ev[e]*MAX_N+eu[e]]=i16(id)}
	active:[MAX_N]bool;branches:[MAX_N*MAX_N]i16;branch_count:[MAX_N]int
	for v:=0;v<n;v+=1 {active[v]=true};active_count:=n
	for active_count>1 {
		if active_count==2 {pair:[2]int;found:=0;for v:=0;v<n;v+=1 {if active[v] {pair[found]=v;found+=1}};x,y:=pair[0],pair[1];local:=make_rake(&nodes[0],&used,vertex_leaf[x],&branches[x*MAX_N],branch_count[x],&values[0],&edges[0]);if local<0 do return -1;branch:=append_cluster(&nodes[0],&used,BRANCH,int(edge_cluster[x*MAX_N+y]),local,x,&values[0],&edges[0]);if branch<0||branch_count[y]>=MAX_N do return -1;branches[y*MAX_N+branch_count[y]]=i16(branch);branch_count[y]+=1;adj[x*MAX_N+y]=false;adj[y*MAX_N+x]=false;edge_cluster[x*MAX_N+y]=-1;edge_cluster[y*MAX_N+x]=-1;active[x]=false;active_count-=1;break}
		leaves,leaf_neighbor:[MAX_N]int;leaf_count:=0
		for v:=0;v<n;v+=1 {if active[v] {near:[2]int;if neighbor_count(&adj[0],&active[0],n,v,&near[0])==1 {leaves[leaf_count]=v;leaf_neighbor[leaf_count]=near[0];leaf_count+=1}}}
		for i:=0;i<leaf_count;i+=1 {x,y:=leaves[i],leaf_neighbor[i];local:=make_rake(&nodes[0],&used,vertex_leaf[x],&branches[x*MAX_N],branch_count[x],&values[0],&edges[0]);if local<0 do return -1;branch:=append_cluster(&nodes[0],&used,BRANCH,int(edge_cluster[x*MAX_N+y]),local,x,&values[0],&edges[0]);if branch<0||branch_count[y]>=MAX_N do return -1;branches[y*MAX_N+branch_count[y]]=i16(branch);branch_count[y]+=1}
		for i:=0;i<leaf_count;i+=1 {x,y:=leaves[i],leaf_neighbor[i];adj[x*MAX_N+y]=false;adj[y*MAX_N+x]=false;edge_cluster[x*MAX_N+y]=-1;edge_cluster[y*MAX_N+x]=-1;active[x]=false;active_count-=1}
		if active_count<=1 do break
		chosen:[MAX_N]bool;compress:[MAX_N]int;cc:=0
		for x:=0;x<n;x+=1 {if active[x] {near:[2]int;if neighbor_count(&adj[0],&active[0],n,x,&near[0])!=2 do continue;if !chosen[near[0]]&&!chosen[near[1]] {chosen[x]=true;compress[cc]=x;cc+=1}}}
		px,py,pz,pc:[MAX_N]int
		for i:=0;i<cc;i+=1 {x:=compress[i];near:[2]int;_=neighbor_count(&adj[0],&active[0],n,x,&near[0]);y,z:=near[0],near[1];local:=make_rake(&nodes[0],&used,vertex_leaf[x],&branches[x*MAX_N],branch_count[x],&values[0],&edges[0]);if local<0 do return -1;attached:=append_cluster(&nodes[0],&used,ATTACH,int(edge_cluster[y*MAX_N+x]),local,x,&values[0],&edges[0]);if attached<0 do return -1;merged:=append_cluster(&nodes[0],&used,COMPRESS,attached,int(edge_cluster[x*MAX_N+z]),x,&values[0],&edges[0]);if merged<0 do return -1;px[i],py[i],pz[i],pc[i]=x,y,z,merged}
		for i:=0;i<cc;i+=1 {x,y,z:=px[i],py[i],pz[i];adj[y*MAX_N+x]=false;adj[x*MAX_N+y]=false;adj[x*MAX_N+z]=false;adj[z*MAX_N+x]=false;edge_cluster[y*MAX_N+x]=-1;edge_cluster[x*MAX_N+y]=-1;edge_cluster[x*MAX_N+z]=-1;edge_cluster[z*MAX_N+x]=-1;active[x]=false;active_count-=1}
		for i:=0;i<cc;i+=1 {y,z:=py[i],pz[i];adj[y*MAX_N+z]=true;adj[z*MAX_N+y]=true;edge_cluster[y*MAX_N+z]=i16(pc[i]);edge_cluster[z*MAX_N+y]=i16(pc[i])}
	}
	root_vertex:=0;for !active[root_vertex] {root_vertex+=1};root:=make_rake(&nodes[0],&used,vertex_leaf[root_vertex],&branches[root_vertex*MAX_N],branch_count[root_vertex],&values[0],&edges[0]);if root<0 do return -1
	answers:[MAX_Q]i64
	for i:=0;i<q;i+=1 {item:=opitem[i];node_id:=0;if opcode[i]==0 {values[item]=opfirst[i];node_id=vertex_leaf[item];recalculate(&nodes[0],node_id,&values[0],&edges[0])}else{edges[item]=Affine{opfirst[i],opsecond[i]};node_id=edge_leaf[item];recalculate(&nodes[0],node_id,&values[0],&edges[0])};ancestor:=int(nodes[node_id].parent);for ancestor>=0 {recalculate(&nodes[0],ancestor,&values[0],&edges[0]);ancestor=int(nodes[ancestor].parent)};answers[i]=query(&nodes[0],root,&vertex_leaf[0],oproot[i],&values[0]);if answers[i]<0 do return -1}
	for i:=0;i<q;i+=1 {store_le(output,8*i,answers[i])}
	return i64(bytes)
}
