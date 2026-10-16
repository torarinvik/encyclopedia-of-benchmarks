fn maxflow(cap: *const [64]i64, n: usize, source: usize, sink: usize) struct { value: i64, reachable: [8]bool } {
    var residual = cap.*;
    var total: i64 = 0;
    while (true) {
        var parent: [8]i32 = @splat(-1); parent[source] = @intCast(source);
        var queue: [8]usize = undefined; var head: usize = 0; var tail: usize = 1; queue[0] = source;
        while (head < tail and parent[sink] < 0) {
            const u = queue[head]; head += 1;
            for (0..n) |v| { if (residual[u*n+v] > 0 and parent[v] < 0) { parent[v] = @intCast(u); if (v == sink) break; queue[tail] = v; tail += 1; } }
        }
        if (parent[sink] < 0) break;
        var amount: i64 = 1_000_000; var v = sink;
        while (v != source) { const u: usize = @intCast(parent[v]); amount = @min(amount, residual[u*n+v]); v = u; }
        v = sink; while (v != source) { const u: usize = @intCast(parent[v]); residual[u*n+v] -= amount; residual[v*n+u] += amount; v = u; }
        total += amount;
    }
    var reachable: [8]bool = @splat(false); var queue: [8]usize = undefined; var head: usize = 0; var tail: usize = 1; queue[0] = source; reachable[source] = true;
    while (head < tail) { const u = queue[head]; head += 1; for (0..n) |v| { if (!reachable[v] and residual[u*n+v] > 0) { reachable[v] = true; queue[tail] = v; tail += 1; } } }
    return .{ .value = total, .reachable = reachable };
}

export fn gomory_hu_tree(a: [*c]const i64, length: usize) i64 {
    if (a == null or length < 2 or length > 65) return -1;
    const n64 = a[0]; if (n64 < 1 or n64 > 8 or length != 1 + @as(usize, @intCast(n64*n64))) return -1;
    const n: usize = @intCast(n64); var cap: [64]i64 = @splat(0);
    for (0..n*n) |i| { const x=a[1+i]; if (x < 0 or x > 1000) return -1; cap[i]=x; }
    for (0..n) |i| { for (0..n) |j| { if (cap[i*n+j] != (if (i == j) @as(i64,0) else cap[j*n+i])) return -1; } }
    var parent: [8]usize = @splat(0); var weight: [8]i64 = @splat(0);
    for (1..n) |s| { const t=parent[s]; const result=maxflow(&cap,n,s,t); weight[s]=result.value;
        for (0..n) |v| { if (v != s and parent[v] == t and result.reachable[v]) parent[v]=s; }
        if (t != 0 and result.reachable[parent[t]]) { parent[s]=parent[t]; parent[t]=s; weight[s]=weight[t]; weight[t]=result.value; }
    }
    var pair: [64]i64 = @splat(0);
    for (0..n) |source| { var prev: [8]i32 = @splat(-2); var q: [8]usize = undefined; var head: usize=0; var tail: usize=1; q[0]=source; prev[source]=-1;
        while (head<tail) { const u=q[head];head+=1;for (0..n)|v| { if (v!=u and ((v>0 and parent[v]==u) or (u>0 and parent[u]==v)) and prev[v]==-2) {prev[v]=@intCast(u);q[tail]=v;tail+=1;} } }
        for (0..n)|target| { if(target!=source){var x=target;var minimum:i64=1_000_000;while(x!=source){const p:usize=@intCast(prev[x]);const edge=if(x>0 and parent[x]==p)x else p;minimum=@min(minimum,weight[edge]);x=p;}pair[source*n+target]=minimum;} }
    }
    var h:u64=14695981039346656037;for(pair[0..n*n])|value|{var bits:u64=@bitCast(value);for(0..8)|_|{h=(h^(bits&255))*%1099511628211;bits>>=8;}}return @bitCast(h);
}
