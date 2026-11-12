const std = @import("std");

const max_n: usize = 16;
const max_q: usize = 32;
const max_e: usize = 15;
const max_nodes: usize = 75;
const max_input: usize = 143;
const edge_base: i16 = 0;
const edge_compress: i16 = 1;
const rake_zero: i16 = 2;
const rake_merge: i16 = 3;
const rake_branch: i16 = 4;

const Cluster = struct {
    kind: i16 = 0,
    a: i16 = -1,
    b: i16 = -1,
    c: i16 = -1,
    parent: i16 = -1,
    end0: i16 = -1,
    end1: i16 = -1,
    pivot: i16 = -1,
    edge: i16 = -1,
    length: i64 = 0,
    far0: i64 = 0,
    far1: i64 = 0,
    diameter: i64 = 0,
    best1: i64 = 0,
    best2: i64 = 0,
};

fn max64(a: i64, b: i64) i64 { return if (a > b) a else b; }

fn farAt(nodes: *const [max_nodes]Cluster, id: usize, vertex: i16) i64 {
    return if (nodes[id].end0 == vertex) nodes[id].far0 else nodes[id].far1;
}

fn recalc(nodes: *[max_nodes]Cluster, id: usize, weights: *const [max_e]i64) void {
    const x = nodes[id];
    if (x.kind == edge_base) {
        const w = weights[@intCast(x.edge)];
        nodes[id].length = w; nodes[id].far0 = w; nodes[id].far1 = w; nodes[id].diameter = w;
    } else if (x.kind == rake_zero) {
        nodes[id].best1 = 0; nodes[id].best2 = 0; nodes[id].diameter = 0;
    } else if (x.kind == rake_merge) {
        const l = nodes[@intCast(x.a)]; const r = nodes[@intCast(x.b)];
        var first: i64 = 0; var second: i64 = 0;
        const arms = [_]i64{ l.best1,l.best2,r.best1,r.best2 };
        for (arms) |arm| {
            if (arm >= first) { second=first; first=arm; } else if (arm>second) { second=arm; }
        }
        nodes[id].best1=first; nodes[id].best2=second;
        nodes[id].diameter=max64(l.diameter,max64(r.diameter,l.best1+r.best1));
    } else if (x.kind == rake_branch) {
        const e=nodes[@intCast(x.a)]; const local=nodes[@intCast(x.b)];
        const center=farAt(nodes,@intCast(x.a),x.end0); const pivot_far=farAt(nodes,@intCast(x.a),x.pivot);
        nodes[id].best1=max64(center,e.length+local.best1); nodes[id].best2=0;
        nodes[id].diameter=max64(e.diameter,max64(local.diameter,pivot_far+local.best1));
    } else {
        const a=nodes[@intCast(x.a)]; const b=nodes[@intCast(x.b)]; const local=nodes[@intCast(x.c)];
        const ay=farAt(nodes,@intCast(x.a),x.end0); const ap=farAt(nodes,@intCast(x.a),x.pivot);
        const bp=farAt(nodes,@intCast(x.b),x.pivot); const bz=farAt(nodes,@intCast(x.b),x.end1);
        nodes[id].length=a.length+b.length;
        nodes[id].far0=max64(ay,a.length+max64(bp,local.best1));
        nodes[id].far1=max64(bz,b.length+max64(ap,local.best1));
        nodes[id].diameter=max64(a.diameter,max64(b.diameter,max64(local.diameter,
            max64(ap+bp,max64(ap+local.best1,bp+local.best1)))));
    }
}

fn append(nodes: *[max_nodes]Cluster, count: *usize, kind: i16, weights: *const [max_e]i64,
    a: i16,b: i16,c: i16,end0: i16,end1: i16,pivot: i16,edge: i16) i16 {
    if (count.* >= max_nodes) return -1;
    const id=count.*; count.*+=1;
    nodes[id]=.{.kind=kind,.a=a,.b=b,.c=c,.parent=-1,.end0=end0,.end1=end1,.pivot=pivot,.edge=edge};
    for ([_]i16{a,b,c}) |child| { if (child>=0) nodes[@intCast(child)].parent=@intCast(id); }
    recalc(nodes,id,weights);
    return @intCast(id);
}

fn makeRake(nodes: *[max_nodes]Cluster,count: *usize,weights: *const [max_e]i64,
    base: i16,branches: *const [max_n * max_n]i16,branch_offset: usize,branch_count: usize) i16 {
    var level=[_]i16{0} ** (max_n+1); var next=[_]i16{0} ** (max_n+1);
    var len:usize=1; level[0]=base;
    for (0..branch_count) |i| { level[len]=branches[branch_offset+i];len+=1; }
    while(len>1) {
        var next_len:usize=0; var i:usize=0;
        while(i<len) : (i+=2) {
            if(i+1==len) { next[next_len]=level[i];next_len+=1; }
            else { const merged=append(nodes,count,rake_merge,weights,level[i],level[i+1],-1,-1,-1,-1,-1); if(merged<0)return -1;next[next_len]=merged;next_len+=1; }
        }
        @memcpy(level[0..next_len],next[0..next_len]);len=next_len;
    }
    return level[0];
}

fn neighborCount(adj: *const [max_n * max_n]bool,active: *const [max_n]bool,n:usize,v:usize,out:*[2]usize) usize {
    var count:usize=0;
    for(0..n)|other| { if(active[other] and adj[v*max_n+other]) { if(count<2)out[count]=other;count+=1; } }
    return count;
}

fn findRoot(parent: *[max_n]usize, start:usize) usize {
    var v=start;while(parent[v]!=v){parent[v]=parent[parent[v]];v=parent[v];}return v;
}

fn storeLe(output: [*]u8,offset:usize,value:i64) void {
    const bits:u64=@bitCast(value);for(0..8)|b|output[offset+b]=@truncate(bits>>(8*b));
}

export fn dynamic_top_tree_component_diameter(input_opt: ?[*]const i64,length:usize,
    output_opt:?[*]u8,capacity:usize) i64 {
    if(input_opt==null or length<2 or length>max_input)return -1;
    const input=input_opt.?;const nn=input[0];const qq=input[1];
    if(nn<1 or nn>@as(i64,@intCast(max_n)) or qq<0 or qq>@as(i64,@intCast(max_q)))return -1;
    const n:usize=@intCast(nn);const q:usize=@intCast(qq);const edge_end=2+3*(n-1);
    if(length!=edge_end+3*q)return -1;
    var edge_u=[_]usize{0}**max_e;var edge_v=[_]usize{0}**max_e;var dsu=[_]usize{0}**max_n;var weights=[_]i64{0}**max_e;
    for(0..n)|v|dsu[v]=v;
    for(0..n-1)|e|{
        const off=2+3*e;const uv=input[off];const vv=input[off+1];const w=input[off+2];
        if(uv<0 or uv>=nn or vv<0 or vv>=nn or uv==vv or w<0 or w>1000)return -1;
        const u:usize=@intCast(uv);const v:usize=@intCast(vv);const ru=findRoot(&dsu,u);const rv=findRoot(&dsu,v);
        if(ru==rv)return -1;dsu[ru]=rv;edge_u[e]=u;edge_v[e]=v;weights[e]=w;
    }
    const tree_root=findRoot(&dsu,0);for(1..n)|v|{if(findRoot(&dsu,v)!=tree_root)return -1;}
    var op_code=[_]i64{0}**max_q;var op_edge=[_]usize{0}**max_q;var op_value=[_]i64{0}**max_q;var query_count:usize=0;
    for(0..q)|t|{
        const off=edge_end+3*t;const op=input[off];const e=input[off+1];const value=input[off+2];
        if(op==0){if(e<0 or e>=nn-1 or value<0 or value>1000)return -1;}
        else if(op==1){if(e!=0 or value!=0)return -1;query_count+=1;}
        else return -1;
        op_code[t]=op;op_edge[t]=@intCast(e);op_value[t]=value;
    }
    const output_bytes=8*query_count;const output=output_opt orelse {if(output_bytes>0)return -2;return 0;};
    if(output_bytes>0 and capacity<output_bytes)return -2;
    var nodes=[_]Cluster{.{}}**max_nodes;var node_count:usize=0;
    var base_rake=[_]i16{0}**max_n;var base_edge=[_]i16{0}**max_e;
    var adj=[_]bool{false}**(max_n*max_n);var active=[_]bool{false}**max_n;
    var edge_cluster=[_]i16{-1}**(max_n*max_n);var branches=[_]i16{0}**(max_n*max_n);var branch_count=[_]usize{0}**max_n;
    for(0..n)|v|{active[v]=true;base_rake[v]=append(&nodes,&node_count,rake_zero,&weights,-1,-1,-1,-1,-1,-1,-1);if(base_rake[v]<0)return -1;}
    for(0..n-1)|e|{const u=edge_u[e];const v=edge_v[e];const cluster=append(&nodes,&node_count,edge_base,&weights,-1,-1,-1,@intCast(u),@intCast(v),-1,@intCast(e));if(cluster<0)return -1;base_edge[e]=cluster;adj[u*max_n+v]=true;adj[v*max_n+u]=true;edge_cluster[u*max_n+v]=cluster;edge_cluster[v*max_n+u]=cluster;}
    var active_count=n;
    while(active_count>1){
        if(active_count==2){
            var pair=[_]usize{0}**2;var found:usize=0;for(0..n)|v|{if(active[v]){pair[found]=v;found+=1;}}
            const x=pair[0];const y=pair[1];const local=makeRake(&nodes,&node_count,&weights,base_rake[x],&branches,x*max_n,branch_count[x]);if(local<0)return -1;
            const branch=append(&nodes,&node_count,rake_branch,&weights,edge_cluster[x*max_n+y],local,-1,@intCast(y),-1,@intCast(x),-1);if(branch<0 or branch_count[y]>=max_n)return -1;
            branches[y*max_n+branch_count[y]]=branch;branch_count[y]+=1;adj[x*max_n+y]=false;adj[y*max_n+x]=false;edge_cluster[x*max_n+y]=-1;edge_cluster[y*max_n+x]=-1;active[x]=false;active_count-=1;break;
        }
        var leaves=[_]usize{0}**max_n;var leaf_neighbor=[_]usize{0}**max_n;var leaf_count:usize=0;
        for(0..n)|v|{if(active[v]){var a=[_]usize{0}**2;if(neighborCount(&adj,&active,n,v,&a)==1){leaves[leaf_count]=v;leaf_neighbor[leaf_count]=a[0];leaf_count+=1;}}}
        for(0..leaf_count)|i|{const x=leaves[i];const y=leaf_neighbor[i];const local=makeRake(&nodes,&node_count,&weights,base_rake[x],&branches,x*max_n,branch_count[x]);if(local<0)return -1;const branch=append(&nodes,&node_count,rake_branch,&weights,edge_cluster[x*max_n+y],local,-1,@intCast(y),-1,@intCast(x),-1);if(branch<0 or branch_count[y]>=max_n)return -1;branches[y*max_n+branch_count[y]]=branch;branch_count[y]+=1;}
        for(0..leaf_count)|i|{const x=leaves[i];const y=leaf_neighbor[i];adj[x*max_n+y]=false;adj[y*max_n+x]=false;edge_cluster[x*max_n+y]=-1;edge_cluster[y*max_n+x]=-1;active[x]=false;active_count-=1;}
        if(active_count<=1)break;
        var chosen=[_]bool{false}**max_n;var cv=[_]usize{0}**max_n;var cc:usize=0;
        for(0..n)|x|{if(active[x]){var a=[_]usize{0}**2;if(neighborCount(&adj,&active,n,x,&a)!=2)continue;if(!chosen[a[0]] and !chosen[a[1]]){chosen[x]=true;cv[cc]=x;cc+=1;}}}
        var px=[_]usize{0}**max_n;var py=[_]usize{0}**max_n;var pz=[_]usize{0}**max_n;var pc=[_]i16{0}**max_n;
        for(0..cc)|i|{const x=cv[i];var a=[_]usize{0}**2;_=neighborCount(&adj,&active,n,x,&a);const y=a[0];const z=a[1];const local=makeRake(&nodes,&node_count,&weights,base_rake[x],&branches,x*max_n,branch_count[x]);if(local<0)return -1;const cluster=append(&nodes,&node_count,edge_compress,&weights,edge_cluster[y*max_n+x],edge_cluster[x*max_n+z],local,@intCast(y),@intCast(z),@intCast(x),-1);if(cluster<0)return -1;px[i]=x;py[i]=y;pz[i]=z;pc[i]=cluster;}
        for(0..cc)|i|{const x=px[i];const y=py[i];const z=pz[i];adj[y*max_n+x]=false;adj[x*max_n+y]=false;adj[x*max_n+z]=false;adj[z*max_n+x]=false;edge_cluster[y*max_n+x]=-1;edge_cluster[x*max_n+y]=-1;edge_cluster[x*max_n+z]=-1;edge_cluster[z*max_n+x]=-1;active[x]=false;active_count-=1;}
        for(0..cc)|i|{const y=py[i];const z=pz[i];adj[y*max_n+z]=true;adj[z*max_n+y]=true;edge_cluster[y*max_n+z]=pc[i];edge_cluster[z*max_n+y]=pc[i];}
    }
    var root_vertex:usize=0;while(!active[root_vertex]){root_vertex+=1;}
    const root=makeRake(&nodes,&node_count,&weights,base_rake[root_vertex],&branches,root_vertex*max_n,branch_count[root_vertex]);if(root<0)return -1;
    var staged=[_]i64{0}**max_q;var staged_count:usize=0;
    for(0..q)|t|{if(op_code[t]==0){const e=op_edge[t];weights[e]=op_value[t];var node:usize=@intCast(base_edge[e]);recalc(&nodes,node,&weights);var ancestor=nodes[node].parent;while(ancestor>=0){node=@intCast(ancestor);recalc(&nodes,node,&weights);ancestor=nodes[node].parent;}}else{staged[staged_count]=nodes[@intCast(root)].diameter;staged_count+=1;}}
    for(0..staged_count)|i|storeLe(output,8*i,staged[i]);
    return @intCast(output_bytes);
}
