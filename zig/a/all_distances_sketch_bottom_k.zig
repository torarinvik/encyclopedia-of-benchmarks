fn put_i64(out: [*]u8, offset: usize, x: i64) void {
    const bits: u64 = @bitCast(x);
    for (0..8) |b| out[offset+b] = @truncate(bits >> @intCast(8*b));
}

export fn all_distances_sketch_bottom_k(input: [*]const i64, length: usize, output: [*]u8, capacity: usize) i64 {
    if (@intFromPtr(input)==0 or length<6 or length>104) return -1;
    const n0=input[0];const m0=input[1];const k0=input[2];const s0=input[3];
    if(n0<2 or n0>10 or m0<0 or m0>n0*(n0-1) or k0<1 or k0>n0 or s0<0 or s0>=n0)return -1;
    const n:usize=@intCast(n0);const m:usize=@intCast(m0);const k:usize=@intCast(k0);const source:usize=@intCast(s0);
    if(length!=4+n+2*m)return -1;
    var rank=[_]i64{0}**10;var used=[_]bool{false}**10;
    for(0..n)|i|{const r=input[4+i];if(r<0 or r>=n0 or used[@intCast(r)])return -1;used[@intCast(r)]=true;rank[i]=r;}
    var adj=[_]bool{false}**100;
    for(0..m)|e|{const u0=input[4+n+2*e];const v0=input[5+n+2*e];if(u0<0 or u0>=n0 or v0<0 or v0>=n0 or u0==v0)return -1;const u:usize=@intCast(u0);const v:usize=@intCast(v0);if(adj[u*10+v])return -1;adj[u*10+v]=true;}
    var dist=[_]i64{ -1 }**10;var queue=[_]usize{0}**10;var head:usize=0;var tail:usize=0;dist[source]=0;queue[tail]=source;tail+=1;
    while(head<tail):(head+=1){const u=queue[head];for(0..n)|v|{if(adj[u*10+v] and dist[v]<0){dist[v]=dist[u]+1;queue[tail]=v;tail+=1;}}}
    var staged=[_]i64{0}**21;var count:usize=0;
    for(0..n)|d|{for(0..n)|v|{if(dist[v]!=@as(i64,@intCast(d)))continue;var less:usize=0;for(0..n)|x|{if(dist[x]>=0 and (dist[x]<dist[v] or (dist[x]==dist[v] and x<=v)) and rank[x]<rank[v])less+=1;}if(less<k){staged[1+2*count]=@intCast(v);staged[2+2*count]=dist[v];count+=1;}}}
    staged[0]=@intCast(count);const words=1+2*count;const bytes=8*words;if(@intFromPtr(output)==0 or capacity<bytes)return -2;
    for(0..words)|i|put_i64(output,8*i,staged[i]);return @intCast(bytes);
}
