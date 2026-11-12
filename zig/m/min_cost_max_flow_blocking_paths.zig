// Clean-room shortest-path tight-edge blocking-flow method; see package RIGHTS.md.
const INF: i64 = 1 << 60;
const Edge = struct { from: usize, to: usize, rev: usize, cap: i64, cost: i64 };

fn sendTightLevelFlow(u: usize, sink: usize, limit: i64, edges: *[32]Edge,
    arc_count: usize, dist: *[8]i64, level: *[8]i32, current: *[8]usize) i64 {
    if (u == sink) return limit;
    while (current.*[u] < arc_count) {
        const e = current.*[u];
        if (edges.*[e].from != u or edges.*[e].cap <= 0) { current.*[u] += 1; continue; }
        const v = edges.*[e].to;
        if (dist.*[v] == INF or dist.*[v] != dist.*[u] + edges.*[e].cost or
            level.*[v] != level.*[u] + 1) { current.*[u] += 1; continue; }
        const amount = @min(limit, edges.*[e].cap);
        const sent = sendTightLevelFlow(v, sink, amount, edges, arc_count, dist, level, current);
        if (sent > 0) {
            const reverse = edges.*[e].rev;
            edges.*[e].cap -= sent;
            edges.*[reverse].cap += sent;
            if (edges.*[e].cap == 0) current.*[u] += 1;
            return sent;
        }
        current.*[u] += 1;
    }
    return 0;
}

pub export fn min_cost_max_flow_blocking_paths(values: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    const input = values orelse return -1;
    if (length < 5 or length > 69) return -1;
    const n0 = input[0]; const m0 = input[1];
    const source0 = input[2]; const sink0 = input[3]; const flow_limit = input[4];
    if (n0 < 2 or n0 > 8 or m0 < 0 or m0 > 16 or length != 5 + 4 * @as(usize, @intCast(m0))) return -1;
    if (source0 < 0 or source0 >= n0 or sink0 < 0 or sink0 >= n0 or source0 == sink0 or flow_limit < 0 or flow_limit > 16) return -1;
    const n: usize = @intCast(n0); const m: usize = @intCast(m0);
    const source: usize = @intCast(source0); const sink: usize = @intCast(sink0);
    var edges: [32]Edge = undefined;
    for (0..m) |i| {
        const u0=input[5+4*i]; const v0=input[6+4*i]; const cap=input[7+4*i]; const cost=input[8+4*i];
        if (u0 < 0 or u0 >= n0 or v0 < 0 or v0 >= n0 or cap < 0 or cap > 5 or cost < 0 or cost > 20) return -1;
        const e=2*i; const u:usize=@intCast(u0); const v:usize=@intCast(v0);
        edges[e]=.{.from=u,.to=v,.rev=e+1,.cap=cap,.cost=cost};
        edges[e+1]=.{.from=v,.to=u,.rev=e,.cap=0,.cost=-cost};
    }
    const out=output orelse return -2;
    if (output_capacity < 16) return -2;
    var total_flow:i64=0; var total_cost:i64=0;
    while (total_flow < flow_limit) {
        var dist=[_]i64{INF} ** 8;
        var queue=[_]usize{0} ** 8; var in_queue=[_]bool{false} ** 8;
        dist[source]=0;
        var head:usize=0; var tail:usize=0; var queued:usize=0;
        queue[tail]=source; tail=(tail+1)%n; queued+=1; in_queue[source]=true;
        while (queued>0) {
            const u=queue[head]; head=(head+1)%n; queued-=1; in_queue[u]=false;
            for (0..2*m) |e| {
                if (edges[e].from!=u or edges[e].cap<=0) continue;
                const v=edges[e].to; const candidate=dist[u]+edges[e].cost;
                if (candidate<dist[v]) {
                    dist[v]=candidate;
                    if (!in_queue[v]) { queue[tail]=v; tail=(tail+1)%n; queued+=1; in_queue[v]=true; }
                }
            }
        }
        if (dist[sink]==INF) break;
        while (total_flow < flow_limit) {
            var level=[_]i32{-1} ** 8; var breadth=[_]usize{0} ** 8; var current=[_]usize{0} ** 8;
            var first:usize=0; var last:usize=0;
            level[source]=0; breadth[last]=source; last+=1;
            while (first<last) {
                const u=breadth[first]; first+=1;
                for (0..2*m) |e| {
                    if (edges[e].from!=u or edges[e].cap<=0) continue;
                    const v=edges[e].to;
                    if (dist[v]==dist[u]+edges[e].cost and level[v]<0) { level[v]=level[u]+1; breadth[last]=v; last+=1; }
                }
            }
            if (level[sink]<0) break;
            const amount=sendTightLevelFlow(source,sink,flow_limit-total_flow,&edges,2*m,&dist,&level,&current);
            if (amount==0) break;
            total_flow+=amount; total_cost+=amount*dist[sink];
        }
    }
    const flow_bits:u64=@intCast(total_flow); const cost_bits:u64=@intCast(total_cost);
    for (0..8) |i| { out[i]=@truncate(flow_bits >> @intCast(8*i)); out[8+i]=@truncate(cost_bits >> @intCast(8*i)); }
    return 16;
}
