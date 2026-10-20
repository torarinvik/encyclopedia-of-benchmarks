// Based on AtCoder Library mcf_graph::flow (CC0 1.0); see benchmarks/m/min_cost_max_flow/LICENSE.txt.
const INF: i64 = 1 << 60;
const Edge = struct { from: usize, to: usize, rev: usize, cap: i64, cost: i64 };

pub export fn min_cost_max_flow(values: ?[*]const i64, length: usize,
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
    var potential=[_]i64{0} ** 8;
    var total_flow:i64=0; var total_cost:i64=0;
    while (total_flow < flow_limit) {
        var dist=[_]i64{INF} ** 8; var parent=[_]usize{32} ** 8; var used=[_]bool{false} ** 8;
        dist[source]=0;
        for (0..n) |_| {
            var chosen:usize=8;
            for (0..n) |v| { if (!used[v] and dist[v]!=INF and (chosen==8 or dist[v]<dist[chosen])) { chosen=v; } }
            if (chosen==8) break;
            used[chosen]=true;
            for (0..2*m) |e| {
                if (edges[e].from!=chosen or edges[e].cap<=0) continue;
                const v=edges[e].to; const candidate=dist[chosen]+edges[e].cost+potential[chosen]-potential[v];
                if (!used[v] and candidate<dist[v]) { dist[v]=candidate; parent[v]=e; }
            }
        }
        if (dist[sink]==INF) break;
        for (0..n) |v| { if (dist[v]!=INF) { potential[v]+=dist[v]; } }
        var amount=flow_limit-total_flow; var v=sink;
        while (v!=source) { const e=parent[v]; if (e==32) return -1; amount=@min(amount,edges[e].cap); v=edges[e].from; }
        v=sink;
        while (v!=source) { const e=parent[v]; const prev=edges[e].from; const rev=edges[e].rev; edges[e].cap-=amount; edges[rev].cap+=amount; v=prev; }
        total_flow+=amount; total_cost+=amount*(potential[sink]-potential[source]);
    }
    const flow_bits:u64=@intCast(total_flow); const cost_bits:u64=@intCast(total_cost);
    for (0..8) |i| { out[i]=@truncate(flow_bits >> @intCast(8*i)); out[8+i]=@truncate(cost_bits >> @intCast(8*i)); }
    return 16;
}
