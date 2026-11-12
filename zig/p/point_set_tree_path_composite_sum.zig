const max_n: usize = 16;
const max_q: usize = 32;
const max_e: usize = 15;
const max_nodes: usize = 75;
const max_input: usize = 238;
const modulus: i64 = 998244353;
const vertex_kind: i16 = 0;
const edge_kind: i16 = 1;
const rake_kind: i16 = 2;
const branch_kind: i16 = 3;
const attach_kind: i16 = 4;
const compress_kind: i16 = 5;

const Affine = struct { mul: i64 = 0, add: i64 = 0 };
const Cluster = struct {
    kind: i16 = 0, a: i16 = -1, b: i16 = -1, parent: i16 = -1, shared: i16 = -1,
    boundary0: i16 = -1, boundary1: i16 = -1, boundary_count: i16 = 0, edge: i16 = -1,
    has0: bool = false, has1: bool = false, mask: u16 = 0, count: i32 = 0,
    sum0: i64 = 0, sum1: i64 = 0, forward: Affine = .{}, reverse: Affine = .{},
};
const Context = struct { sum0: i64 = 0, count0: i64 = 0, sum1: i64 = 0, count1: i64 = 0 };

fn norm(x: i64) i64 { const y = @mod(x, modulus); return y; }
fn identity() Affine { return .{ .mul = 1, .add = 0 }; }
fn compose(outer: Affine, inner: Affine) Affine {
    return .{ .mul = outer.mul * inner.mul % modulus,
              .add = (outer.mul * inner.add + outer.add) % modulus };
}
fn apply(map: Affine, sum: i64, count: i64) i64 { return (map.mul * sum + map.add * count) % modulus; }
fn boundaryIndex(node: Cluster, vertex: i16) i16 {
    if (node.boundary0 == vertex) return 0;
    if (node.boundary_count == 2 and node.boundary1 == vertex) return 1;
    return -1;
}
fn has(node: Cluster, vertex: i16) bool {
    const index = boundaryIndex(node, vertex);
    return if (index == 0) node.has0 else if (index == 1) node.has1 else false;
}
fn sumAt(node: Cluster, vertex: i16) i64 { return if (boundaryIndex(node, vertex) == 0) node.sum0 else node.sum1; }
fn mapAt(node: Cluster, from: i16, to: i16) Affine {
    if (from == to or node.boundary_count != 2) return identity();
    return if (node.boundary0 == from and node.boundary1 == to) node.forward else node.reverse;
}
fn recalc(nodes: *[max_nodes]Cluster, id: usize, values: *const [max_n]i64, edges: *const [max_e]Affine) void {
    const x = nodes[id];
    if (x.kind == vertex_kind) {
        nodes[id].count = 1; nodes[id].mask = @as(u16, 1) << @intCast(x.boundary0);
        nodes[id].sum0 = values[@intCast(x.boundary0)]; nodes[id].has0 = true; return;
    }
    if (x.kind == edge_kind) { nodes[id].forward = edges[@intCast(x.edge)]; nodes[id].reverse = edges[@intCast(x.edge)]; return; }
    const a = nodes[@intCast(x.a)]; const b = nodes[@intCast(x.b)];
    const overlap = has(a, x.shared) and has(b, x.shared);
    const removed: i32 = if (overlap) 1 else 0;
    const duplicate: i64 = if (overlap) values[@intCast(x.shared)] else 0;
    nodes[id].count = a.count + b.count - removed; nodes[id].mask = a.mask | b.mask;
    const boundaries = [_]i16{x.boundary0, x.boundary1};
    for (0..@intCast(x.boundary_count)) |i| {
        const boundary = boundaries[i];
        const total = if (boundary == x.shared)
            @mod(sumAt(a, x.shared) + sumAt(b, x.shared) - duplicate, modulus)
        else if (boundaryIndex(a, boundary) >= 0)
            @mod(sumAt(a, boundary) + apply(mapAt(a, boundary, x.shared),
                @mod(sumAt(b, x.shared) - duplicate, modulus), @intCast(b.count - removed)), modulus)
        else
            @mod(sumAt(b, boundary) + apply(mapAt(b, boundary, x.shared),
                @mod(sumAt(a, x.shared) - duplicate, modulus), @intCast(a.count - removed)), modulus);
        const boundary_has = has(a, boundary) or has(b, boundary);
        if (i == 0) { nodes[id].sum0 = total; nodes[id].has0 = boundary_has; }
        else { nodes[id].sum1 = total; nodes[id].has1 = boundary_has; }
    }
    if (x.boundary_count == 2) {
        const u = x.boundary0; const v = x.boundary1;
        const au = boundaryIndex(a, u) >= 0; const av = boundaryIndex(a, v) >= 0;
        const bu = boundaryIndex(b, u) >= 0; const bv = boundaryIndex(b, v) >= 0;
        if (au and av) { nodes[id].forward = mapAt(a, u, v); nodes[id].reverse = mapAt(a, v, u); }
        else if (bu and bv) { nodes[id].forward = mapAt(b, u, v); nodes[id].reverse = mapAt(b, v, u); }
        else {
            nodes[id].forward = compose(mapAt(a, u, x.shared), mapAt(b, x.shared, v));
            nodes[id].reverse = compose(mapAt(b, v, x.shared), mapAt(a, x.shared, u));
        }
    }
}
fn append(nodes: *[max_nodes]Cluster, used: *usize, kind: i16, a_id: i16, b_id: i16,
    shared: i16, values: *const [max_n]i64, edges: *const [max_e]Affine) i16 {
    if (used.* >= max_nodes) return -1;
    const id = used.*; used.* += 1;
    var node = Cluster{ .kind=kind, .a=a_id, .b=b_id, .parent=-1, .shared=shared,
        .edge=-1, .forward=identity(), .reverse=identity() };
    if (kind == vertex_kind) { node.boundary0=shared; node.boundary_count=1; }
    else if (kind == edge_kind) { node.boundary0=a_id; node.boundary1=b_id; node.boundary_count=2; node.edge=shared; }
    else {
        const a=nodes[@intCast(a_id)];const b=nodes[@intCast(b_id)];
        const ao=if(a.boundary_count==2 and a.boundary0==shared)a.boundary1 else a.boundary0;
        const bo=if(b.boundary_count==2 and b.boundary0==shared)b.boundary1 else b.boundary0;
        if(kind==rake_kind){node.boundary0=shared;node.boundary_count=1;}
        else if(kind==branch_kind){node.boundary0=ao;node.boundary_count=1;}
        else if(kind==attach_kind){node.boundary0=a.boundary0;node.boundary1=a.boundary1;node.boundary_count=2;}
        else{node.boundary0=ao;node.boundary1=bo;node.boundary_count=2;}
        nodes[@intCast(a_id)].parent=@intCast(id);nodes[@intCast(b_id)].parent=@intCast(id);
    }
    nodes[id]=node;recalc(nodes,id,values,edges);return @intCast(id);
}
fn makeRake(nodes: *[max_nodes]Cluster, used: *usize, base: i16, branches: *const [max_n * max_n]i16,
    offset: usize, branch_count: usize, values: *const [max_n]i64, edges: *const [max_e]Affine) i16 {
    var level=[_]i16{0}**(max_n+1);var next=[_]i16{0}**(max_n+1);var len:usize=1;level[0]=base;
    for(0..branch_count)|i|{level[len]=branches[offset+i];len+=1;}
    while(len>1){var next_len:usize=0;var i:usize=0;while(i<len):(i+=2){if(i+1==len){next[next_len]=level[i];next_len+=1;}else{const shared=nodes[@intCast(level[i])].boundary0;const merged=append(nodes,used,rake_kind,level[i],level[i+1],shared,values,edges);if(merged<0)return -1;next[next_len]=merged;next_len+=1;}}@memcpy(level[0..next_len],next[0..next_len]);len=next_len;}
    return level[0];
}
fn neighborCount(adj:*const [max_n*max_n]bool,active:*const [max_n]bool,n:usize,v:usize,out:*[2]usize)usize{var count:usize=0;for(0..n)|u|{if(active[u] and adj[v*max_n+u]){if(count<2)out[count]=u;count+=1;}}return count;}
fn findRoot(parent:*[max_n]usize,start:usize)usize{var v=start;while(parent[v]!=v){parent[v]=parent[parent[v]];v=parent[v];}return v;}
fn contextAt(node:Cluster,context:Context,vertex:i16,out:*[2]i64)void{const i=boundaryIndex(node,vertex);out[0]=0;out[1]=0;if(i==0){out[0]=context.sum0;out[1]=context.count0;}else if(i==1){out[0]=context.sum1;out[1]=context.count1;}}
fn childContext(nodes:*const [max_nodes]Cluster,parent_id:usize,child_id:usize,context:Context,values:*const [max_n]i64)Context{
    const p=nodes[parent_id];const child=nodes[child_id];const sibling_id=if(child_id==@as(usize,@intCast(p.a)))@as(usize,@intCast(p.b)) else @as(usize,@intCast(p.a));const sibling=nodes[sibling_id];const x=p.shared;
    const overlap=has(child,x) and has(sibling,x);const removed:i64=if(overlap)1 else 0;var sum_x=@mod(sumAt(sibling,x)-(if(overlap)values[@intCast(x)] else 0),modulus);var count_x=@as(i64,sibling.count)-removed;
    const sb=[_]i16{sibling.boundary0,sibling.boundary1};for(0..@intCast(sibling.boundary_count))|i|{const boundary=sb[i];if(boundaryIndex(p,boundary)<0)continue;var outside=[_]i64{0,0};contextAt(p,context,boundary,&outside);sum_x=@mod(sum_x+apply(mapAt(sibling,x,boundary),outside[0],outside[1]),modulus);count_x+=outside[1];}
    var result=Context{};const cb=[_]i16{child.boundary0,child.boundary1};for(0..@intCast(child.boundary_count))|i|{const boundary=cb[i];var sum=sum_x;var count=count_x;if(boundary!=x)sum=apply(mapAt(child,boundary,x),sum_x,count_x);if(boundary!=x and boundaryIndex(p,boundary)>=0){var outside=[_]i64{0,0};contextAt(p,context,boundary,&outside);sum=@mod(sum+outside[0],modulus);count+=outside[1];}if(i==0){result.sum0=sum;result.count0=count;}else{result.sum1=sum;result.count1=count;}}
    return result;
}
fn query(nodes:*const [max_nodes]Cluster,root:usize,vertex_leaf:*const [max_n]i16,vertex:usize,values:*const [max_n]i64)i64{
    var path=[_]usize{0}**max_nodes;var len:usize=1;path[0]=@intCast(vertex_leaf[vertex]);while(path[len-1]!=root and len<max_nodes){const parent=nodes[path[len-1]].parent;if(parent<0)return -1;path[len]=@intCast(parent);len+=1;}if(path[len-1]!=root)return -1;var context=Context{};var i=len;while(i>1){i-=1;context=childContext(nodes,path[i],path[i-1],context,values);}return @mod(nodes[@intCast(vertex_leaf[vertex])].sum0+context.sum0,modulus);
}
fn storeLe(output:[*]u8,offset:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|i|output[offset+i]=@truncate(bits>>(8*i));}

export fn point_set_tree_path_composite_sum(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
    if(input_opt==null or length<2 or length>max_input)return -1;const input=input_opt.?;const nr=input[0];const qr=input[1];if(nr<1 or nr>@as(i64,@intCast(max_n)) or qr<1 or qr>@as(i64,@intCast(max_q)))return -1;const n:usize=@intCast(nr);const q:usize=@intCast(qr);var cursor:usize=2;
    var values=[_]i64{0}**max_n;for(0..n)|v|{if(cursor>=length)return -1;values[v]=input[cursor];cursor+=1;if(values[v]<0 or values[v]>=modulus)return -1;}
    var edge_u=[_]usize{0}**max_e;var edge_v=[_]usize{0}**max_e;var edges=[_]Affine{.{.mul=0,.add=0}}**max_e;var dsu=[_]usize{0}**max_n;for(0..n)|v|dsu[v]=v;
    for(0..n-1)|e|{if(cursor+4>length)return -1;const ur=input[cursor];const vr=input[cursor+1];const mul=input[cursor+2];const add=input[cursor+3];cursor+=4;if(ur<0 or ur>=nr or vr<0 or vr>=nr or ur==vr or mul<1 or mul>=modulus or add<0 or add>=modulus)return -1;const u:usize=@intCast(ur);const v:usize=@intCast(vr);const ru=findRoot(&dsu,u);const rv=findRoot(&dsu,v);if(ru==rv)return -1;dsu[ru]=rv;edge_u[e]=u;edge_v[e]=v;edges[e]=.{.mul=mul,.add=add};}
    const tree_root=findRoot(&dsu,0);for(1..n)|v|{if(findRoot(&dsu,v)!=tree_root)return -1;}
    var op_code=[_]i16{0}**max_q;var op_item=[_]usize{0}**max_q;var op_first=[_]i64{0}**max_q;var op_second=[_]i64{0}**max_q;var op_root=[_]usize{0}**max_q;
    for(0..q)|i|{if(cursor>=length)return -1;const opcode=input[cursor];cursor+=1;if(opcode==0){if(cursor+3>length)return -1;const item=input[cursor];const value=input[cursor+1];const root=input[cursor+2];cursor+=3;if(item<0 or item>=nr or value<0 or value>=modulus or root<0 or root>=nr)return -1;op_code[i]=0;op_item[i]=@intCast(item);op_first[i]=value;op_root[i]=@intCast(root);}else if(opcode==1){if(cursor+4>length)return -1;const item=input[cursor];const mul=input[cursor+1];const add=input[cursor+2];const root=input[cursor+3];cursor+=4;if(item<0 or item>=nr-1 or mul<1 or mul>=modulus or add<0 or add>=modulus or root<0 or root>=nr)return -1;op_code[i]=1;op_item[i]=@intCast(item);op_first[i]=mul;op_second[i]=add;op_root[i]=@intCast(root);}else return -1;}
    if(cursor!=length)return -1;const required=8*q;const output=output_opt orelse return -2;if(capacity<required)return -2;
    var nodes=[_]Cluster{.{}}**max_nodes;var used:usize=0;var vertex_leaf=[_]i16{-1}**max_n;var edge_leaf=[_]i16{-1}**max_e;
    for(0..n)|v|{const id=append(&nodes,&used,vertex_kind,-1,-1,@intCast(v),&values,&edges);if(id<0)return -1;vertex_leaf[v]=id;}
    var adj=[_]bool{false}**(max_n*max_n);var edge_cluster=[_]i16{-1}**(max_n*max_n);
    for(0..n-1)|e|{const id=append(&nodes,&used,edge_kind,@intCast(edge_u[e]),@intCast(edge_v[e]),@intCast(e),&values,&edges);if(id<0)return -1;edge_leaf[e]=id;const u=edge_u[e];const v=edge_v[e];adj[u*max_n+v]=true;adj[v*max_n+u]=true;edge_cluster[u*max_n+v]=id;edge_cluster[v*max_n+u]=id;}
    var active=[_]bool{false}**max_n;var branches=[_]i16{0}**(max_n*max_n);var branch_count=[_]usize{0}**max_n;for(0..n)|v|active[v]=true;var active_count=n;
    while(active_count>1){
        if(active_count==2){var pair=[_]usize{0}**2;var found:usize=0;for(0..n)|v|{if(active[v]){pair[found]=v;found+=1;}}const x=pair[0];const y=pair[1];const local=makeRake(&nodes,&used,vertex_leaf[x],&branches,x*max_n,branch_count[x],&values,&edges);if(local<0)return -1;const branch=append(&nodes,&used,branch_kind,edge_cluster[x*max_n+y],local,@intCast(x),&values,&edges);if(branch<0 or branch_count[y]>=max_n)return -1;branches[y*max_n+branch_count[y]]=branch;branch_count[y]+=1;adj[x*max_n+y]=false;adj[y*max_n+x]=false;edge_cluster[x*max_n+y]=-1;edge_cluster[y*max_n+x]=-1;active[x]=false;active_count-=1;break;}
        var leaves=[_]usize{0}**max_n;var leaf_neighbor=[_]usize{0}**max_n;var leaf_count:usize=0;for(0..n)|v|{if(active[v]){var near=[_]usize{0}**2;if(neighborCount(&adj,&active,n,v,&near)==1){leaves[leaf_count]=v;leaf_neighbor[leaf_count]=near[0];leaf_count+=1;}}}
        for(0..leaf_count)|i|{const x=leaves[i];const y=leaf_neighbor[i];const local=makeRake(&nodes,&used,vertex_leaf[x],&branches,x*max_n,branch_count[x],&values,&edges);if(local<0)return -1;const branch=append(&nodes,&used,branch_kind,edge_cluster[x*max_n+y],local,@intCast(x),&values,&edges);if(branch<0 or branch_count[y]>=max_n)return -1;branches[y*max_n+branch_count[y]]=branch;branch_count[y]+=1;}
        for(0..leaf_count)|i|{const x=leaves[i];const y=leaf_neighbor[i];adj[x*max_n+y]=false;adj[y*max_n+x]=false;edge_cluster[x*max_n+y]=-1;edge_cluster[y*max_n+x]=-1;active[x]=false;active_count-=1;}
        if(active_count<=1)break;var chosen=[_]bool{false}**max_n;var compress=[_]usize{0}**max_n;var cc:usize=0;for(0..n)|x|{if(active[x]){var near=[_]usize{0}**2;if(neighborCount(&adj,&active,n,x,&near)!=2)continue;if(!chosen[near[0]] and !chosen[near[1]]){chosen[x]=true;compress[cc]=x;cc+=1;}}}
        var px=[_]usize{0}**max_n;var py=[_]usize{0}**max_n;var pz=[_]usize{0}**max_n;var pc=[_]i16{0}**max_n;
        for(0..cc)|i|{const x=compress[i];var near=[_]usize{0}**2;_=neighborCount(&adj,&active,n,x,&near);const y=near[0];const z=near[1];const local=makeRake(&nodes,&used,vertex_leaf[x],&branches,x*max_n,branch_count[x],&values,&edges);if(local<0)return -1;const attached=append(&nodes,&used,attach_kind,edge_cluster[y*max_n+x],local,@intCast(x),&values,&edges);if(attached<0)return -1;const merged=append(&nodes,&used,compress_kind,attached,edge_cluster[x*max_n+z],@intCast(x),&values,&edges);if(merged<0)return -1;px[i]=x;py[i]=y;pz[i]=z;pc[i]=merged;}
        for(0..cc)|i|{const x=px[i];const y=py[i];const z=pz[i];adj[y*max_n+x]=false;adj[x*max_n+y]=false;adj[x*max_n+z]=false;adj[z*max_n+x]=false;edge_cluster[y*max_n+x]=-1;edge_cluster[x*max_n+y]=-1;edge_cluster[x*max_n+z]=-1;edge_cluster[z*max_n+x]=-1;active[x]=false;active_count-=1;}
        for(0..cc)|i|{const y=py[i];const z=pz[i];adj[y*max_n+z]=true;adj[z*max_n+y]=true;edge_cluster[y*max_n+z]=pc[i];edge_cluster[z*max_n+y]=pc[i];}
    }
    var root_vertex:usize=0;while(!active[root_vertex]){root_vertex+=1;}const root=makeRake(&nodes,&used,vertex_leaf[root_vertex],&branches,root_vertex*max_n,branch_count[root_vertex],&values,&edges);if(root<0)return -1;
    var answers=[_]i64{0}**max_q;for(0..q)|i|{const item=op_item[i];var node_id:usize=0;if(op_code[i]==0){values[item]=op_first[i];node_id=@intCast(vertex_leaf[item]);recalc(&nodes,node_id,&values,&edges);}else{edges[item]=.{.mul=op_first[i],.add=op_second[i]};node_id=@intCast(edge_leaf[item]);recalc(&nodes,node_id,&values,&edges);}var ancestor=nodes[node_id].parent;while(ancestor>=0){node_id=@intCast(ancestor);recalc(&nodes,node_id,&values,&edges);ancestor=nodes[node_id].parent;}answers[i]=query(&nodes,@intCast(root),&vertex_leaf,op_root[i],&values);if(answers[i]<0)return -1;}
    for(0..q)|i|storeLe(output,8*i,answers[i]);return @intCast(required);
}
