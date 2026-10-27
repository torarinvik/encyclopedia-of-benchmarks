const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 95;
const MAX_OUTPUT: usize = 176;

fn findRoot(parent: *[MAX_N]usize, value: usize) usize {
    var x = value;
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| { const shift: u6 = @intCast(i*8); output[offset+i] = @truncate(bits >> shift); }
}

export fn truthful_multicast_pmst_tree(values: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 4 or length > MAX_INPUT) return -1;
    if (values[0] < 2 or values[0] > @as(i64,@intCast(MAX_N)) or values[1] < values[0]-1 or values[1] > @as(i64,@intCast(MAX_M)) or
        values[2] < 0 or values[2] >= values[0] or values[3] < 1 or values[3] >= values[0]) return -1;
    const n: usize = @intCast(values[0]); const m: usize = @intCast(values[1]); const source: usize = @intCast(values[2]); const r: usize = @intCast(values[3]);
    if (length != 4+3*m+r) return -1;
    var eu: [MAX_M]usize = @splat(0); var ev: [MAX_M]usize = @splat(0); var ew: [MAX_M]i64 = @splat(0); var order: [MAX_M]usize = @splat(0);
    var previous_u: i64 = -1; var previous_v: i64 = -1;
    for (0..m) |i| {
        const u=values[4+3*i];const v=values[5+3*i];const w=values[6+3*i];
        if(u<0 or v<=u or v>=@as(i64,@intCast(n)) or w<1 or w>100 or (i>0 and (u<previous_u or (u==previous_u and v<=previous_v))))return -1;
        eu[i]=@intCast(u);ev[i]=@intCast(v);ew[i]=w;order[i]=i;previous_u=u;previous_v=v;
    }
    var receivers: [MAX_N]usize = @splat(0);var previous_receiver: i64 = -1;
    for(0..r)|i|{const x=values[4+3*m+i];if(x<0 or x>=@as(i64,@intCast(n)) or x==@as(i64,@intCast(source)) or (i>0 and x<=previous_receiver))return -1;receivers[i]=@intCast(x);previous_receiver=x;}
    for(1..m)|i|{const key=order[i];var j=i;while(j>0){const q=order[j-1];if(ew[q]<ew[key] or (ew[q]==ew[key] and (eu[q]<eu[key] or (eu[q]==eu[key] and ev[q]<ev[key]))))break;order[j]=q;j-=1;}order[j]=key;}
    var dsu: [MAX_N]usize = @splat(0);for(0..n)|i|dsu[i]=i;
    var tu: [MAX_N]usize = @splat(0);var tv: [MAX_N]usize = @splat(0);var tw: [MAX_N]i64 = @splat(0);var te:usize=0;
    var z:usize=0;while(z<m and te<n-1):(z+=1){const e=order[z];const a=findRoot(&dsu,eu[e]);const b=findRoot(&dsu,ev[e]);if(a!=b){dsu[a]=b;tu[te]=eu[e];tv[te]=ev[e];tw[te]=ew[e];te+=1;}}
    if(te!=n-1)return -1;
    var edge_at:[MAX_N][MAX_N]i32=@splat(@splat(-1));for(0..te)|e|{edge_at[tu[e]][tv[e]]=@intCast(e);edge_at[tv[e]][tu[e]]=@intCast(e);}
    var parent:[MAX_N]i32=@splat(-1);var parent_edge:[MAX_N]i32=@splat(-1);parent[source]=@intCast(source);var stack:[MAX_N]usize=@splat(0);var top:usize=1;stack[0]=source;
    while(top>0){top-=1;const u=stack[top];for(0..n)|v|{const e=edge_at[u][v];if(e>=0 and parent[v]<0){parent[v]=@intCast(u);parent_edge[v]=e;stack[top]=v;top+=1;}}}
    var keep:[MAX_N]bool=@splat(false);for(0..r)|i|{var v=receivers[i];while(v!=source){if(parent[v]<0)return -1;keep[@intCast(parent_edge[v])]=true;v=@intCast(parent[v]);}}
    var selected:[MAX_N]usize=@splat(0);var count:usize=0;for(0..te)|e|{if(keep[e]){selected[count]=e;count+=1;}}
    for(1..count)|i|{const key=selected[i];var j=i;while(j>0 and (tu[selected[j-1]]>tu[key] or (tu[selected[j-1]]==tu[key] and tv[selected[j-1]]>tv[key]))){selected[j]=selected[j-1];j-=1;}selected[j]=key;}
    const bytes=8*(1+3*count);if(output==null or capacity<bytes)return -2;var staged:[MAX_OUTPUT]u8=@splat(0);putI64Le(&staged,0,@intCast(count));
    for(0..count)|i|{const e=selected[i];putI64Le(&staged,8*(1+3*i),@intCast(tu[e]));putI64Le(&staged,8*(2+3*i),@intCast(tv[e]));putI64Le(&staged,8*(3+3*i),tw[e]);}
    for(0..bytes)|i|output[i]=staged[i];return @intCast(bytes);
}
