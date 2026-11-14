fn send(u: usize, sink: usize, amount: i64, residual: *[16][16]i64,
        level: *const [16]i32, cursor: *[16]usize, n: usize, threshold: i64) i64 {
    if (u == sink) return amount;
    while (cursor[u] < n) {
        const v = cursor[u];
        if (level[v] == level[u]+1 and residual[u][v] >= threshold) {
            const pushed = send(v, sink, @min(amount, residual[u][v]), residual, level, cursor, n, threshold);
            if (pushed > 0) { residual[u][v] -= pushed; residual[v][u] += pushed; return pushed; }
        }
        cursor[u] += 1;
    }
    return 0;
}

export fn dinic_capacity_scaling(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 4 or length > 197) return -1;
    const input = input_opt.?;
    const nv=input[0]; const mv=input[1]; const sv=input[2]; const tv=input[3];
    if (nv<2 or nv>16 or mv<0 or mv>64 or sv<1 or sv>nv or tv<1 or tv>nv or sv==tv) return -1;
    const n: usize=@intCast(nv); const m: usize=@intCast(mv);
    const source: usize=@intCast(sv-1); const sink: usize=@intCast(tv-1);
    if (length != 4+3*m) return -1;
    var residual: [16][16]i64 = @splat(@splat(0));
    for (0..m) |i| {
        const u=input[4+3*i]; const v=input[5+3*i]; const capacity=input[6+3*i];
        if (u<1 or u>nv or v<1 or v>nv or u==v or capacity<0 or capacity>100) return -1;
        residual[@intCast(u-1)][@intCast(v-1)] += capacity;
    }
    var greatest: i64=0;
    for (0..n) |u| for (0..n) |v| { greatest=@max(greatest,residual[u][v]); };
    var threshold: i64=1;
    while (threshold <= @divTrunc(greatest,2)) threshold *= 2;
    if (greatest==0) threshold=0;
    var flow: i64=0;
    while (threshold>0) : (threshold=@divTrunc(threshold,2)) {
        while (true) {
            var level: [16]i32=@splat(-1);
            var queue: [16]usize=@splat(0);
            var head: usize=0; var tail: usize=1;
            level[source]=0; queue[0]=source;
            while (head<tail) {
                const u=queue[head]; head+=1;
                for (0..n) |v| if (level[v]<0 and residual[u][v]>=threshold) {
                    level[v]=level[u]+1; queue[tail]=v; tail+=1;
                };
            }
            if (level[sink]<0) break;
            var cursor: [16]usize=@splat(0);
            while (true) {
                const pushed=send(source,sink,6401,&residual,&level,&cursor,n,threshold);
                if (pushed==0) break;
                flow+=pushed;
            }
        }
    }
    return flow;
}
