const N: usize = 8;
const M: usize = 14;
const MAX_INPUT: usize = 54;
const MAX_OUTPUT: usize = 72;
const INF: i64 = 4611686018427387903;
const Edge = struct { u: usize, v: usize, w: i64 };
const Candidate = struct { a: usize, b: usize, left: usize, right: usize, edge: usize, w: i64 };
const Graph = struct { n: usize, m: usize, k: usize, terminals: [N]usize, edges: [M]Edge };

fn find(parent: *[N]usize, x0: usize) usize {
    var x = x0;
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}
fn join(parent: *[N]usize, rank: *[N]usize, a0: usize, b0: usize) bool {
    var a = find(parent, a0); var b = find(parent, b0);
    if (a == b) return false;
    if (rank[a] < rank[b]) { const t = a; a = b; b = t; }
    parent[b] = a; if (rank[a] == rank[b]) rank[a] += 1; return true;
}
fn candidateBefore(a: Candidate, b: Candidate) bool {
    if (a.w != b.w) return a.w < b.w;
    if (a.a != b.a) return a.a < b.a;
    if (a.b != b.b) return a.b < b.b;
    if (a.left != b.left) return a.left < b.left;
    if (a.right != b.right) return a.right < b.right;
    return a.edge < b.edge;
}
fn parse(input: [*c]const i64, length: usize) ?Graph {
    if (input == null or length < 3 or length > MAX_INPUT) return null;
    const n0 = input[0]; const m0 = input[1]; const k0 = input[2];
    if (n0 < 2 or n0 > N or m0 < 1 or m0 > M or k0 < 2 or k0 > n0) return null;
    const n: usize = @intCast(n0); const m: usize = @intCast(m0); const k: usize = @intCast(k0);
    if (length < 3 + k + 3 * m) return null;
    var g = Graph{ .n = n, .m = m, .k = k, .terminals = [_]usize{0} ** N, .edges = [_]Edge{.{ .u=0, .v=0, .w=0 }} ** M };
    var is_term = [_]bool{false} ** N; var at: usize = 3;
    for (0..k) |i| {
        const t0 = input[at]; at += 1;
        if (t0 < 0 or t0 >= n0) return null;
        const t: usize = @intCast(t0); if (is_term[t]) return null;
        g.terminals[i] = t; is_term[t] = true;
    }
    var seen = [_]bool{false} ** (N * N);
    for (0..m) |e| {
        const u0 = input[at]; const v0 = input[at+1]; const w = input[at+2]; at += 3;
        if (u0 < 0 or u0 >= v0 or v0 >= n0 or w < 1 or w > 9) return null;
        const u: usize = @intCast(u0); const v: usize = @intCast(v0);
        const ix = u * N + v; if (seen[ix]) return null; seen[ix] = true;
        g.edges[e] = .{ .u=u, .v=v, .w=w };
    }
    if (at != length) return null;
    var visited = [_]bool{false} ** N; var queue = [_]usize{0} ** N;
    var head: usize = 0; var tail: usize = 0; visited[0] = true; queue[tail] = 0; tail += 1;
    while (head < tail) {
        const u = queue[head]; head += 1;
        for (0..m) |e| {
            const edge = g.edges[e]; const v = if (edge.u == u) edge.v else if (edge.v == u) edge.u else N;
            if (v < N and !visited[v]) { visited[v] = true; queue[tail] = v; tail += 1; }
        }
    }
    for (0..n) |v| if (!visited[v]) return null;
    return g;
}

const Answer = struct { cost: i64, edges: [M]usize, count: usize };
fn solve(g: Graph) ?Answer {
    var dist = [_]i64{INF} ** N; var owner = [_]usize{N} ** N;
    var pred = [_]usize{N} ** N; var pred_edge = [_]usize{M} ** N; var settled = [_]bool{false} ** N;
    for (0..g.k) |i| { const t = g.terminals[i]; dist[t] = 0; owner[t] = t; }
    for (0..g.n) |_| {
        var current: usize = N;
        for (0..g.n) |v| if (!settled[v] and (current == N or dist[v] < dist[current] or
            (dist[v] == dist[current] and (owner[v] < owner[current] or (owner[v] == owner[current] and v < current))))) { current = v; };
        if (current == N or dist[current] == INF) break;
        settled[current] = true;
        for (0..g.m) |e| {
            const edge = g.edges[e]; const v = if (edge.u == current) edge.v else if (edge.v == current) edge.u else N;
            if (v == N) continue;
            const nd = dist[current] + edge.w;
            if (nd < dist[v] or (nd == dist[v] and owner[current] < owner[v])) {
                dist[v] = nd; owner[v] = owner[current]; pred[v] = current; pred_edge[v] = e;
            } else if (nd == dist[v] and owner[current] == owner[v] and !settled[v] and
                (pred[v] == N or current < pred[v] or (current == pred[v] and e < pred_edge[v]))) {
                pred[v] = current; pred_edge[v] = e;
            }
        }
    }
    for (0..g.n) |v| if (dist[v] == INF or owner[v] == N) return null;
    var has = [_]bool{false} ** (N * N); var best = [_]Candidate{.{ .a=0,.b=0,.left=0,.right=0,.edge=0,.w=0 }} ** (N * N);
    for (0..g.m) |e| {
        const edge = g.edges[e]; var a = owner[edge.u]; var b = owner[edge.v]; if (a == b) continue;
        var left = edge.u; var right = edge.v;
        if (a > b) { const tmp = a; a = b; b = tmp; left = edge.v; right = edge.u; }
        const ix = a * N + b; const c = Candidate{ .a=a,.b=b,.left=left,.right=right,.edge=e,.w=dist[edge.u]+edge.w+dist[edge.v] };
        if (!has[ix] or candidateBefore(c,best[ix])) { has[ix] = true; best[ix] = c; }
    }
    var candidates = [_]Candidate{.{ .a=0,.b=0,.left=0,.right=0,.edge=0,.w=0 }} ** M; var cn: usize = 0;
    for (0..g.n) |a| for (a+1..g.n) |b| { const ix=a*N+b; if (has[ix]) { candidates[cn]=best[ix];cn+=1; } };
    for (1..cn) |i| { const x=candidates[i];var j=i;while(j>0 and candidateBefore(x,candidates[j-1])){candidates[j]=candidates[j-1];j-=1;}candidates[j]=x; }
    var parent = [_]usize{0} ** N; var ranks = [_]usize{0} ** N; for (0..g.n) |v| parent[v]=v;
    var chosen = [_]usize{0} ** N; var ch: usize=0;
    for (0..cn) |i| { if(ch==g.k-1) break; if(join(&parent,&ranks,candidates[i].a,candidates[i].b)){chosen[ch]=i;ch+=1;} }
    if(ch!=g.k-1)return null;
    var used = [_]bool{false} ** M;
    for(0..ch)|i|{const c=candidates[chosen[i]];used[c.edge]=true;var x=c.left;while(x!=c.a){if(pred_edge[x]==M)return null;used[pred_edge[x]]=true;x=pred[x];}x=c.right;while(x!=c.b){if(pred_edge[x]==M)return null;used[pred_edge[x]]=true;x=pred[x];}}
    var order=[_]usize{0}**M;var on:usize=0;for(0..g.m)|e|{if(used[e]){order[on]=e;on+=1;}}
    for(1..on)|i|{const x=order[i];var j=i;while(j>0 and (g.edges[x].w<g.edges[order[j-1]].w or (g.edges[x].w==g.edges[order[j-1]].w and x<order[j-1]))){order[j]=order[j-1];j-=1;}order[j]=x;}
    for(0..g.n)|v|{parent[v]=v;ranks[v]=0;}var tree=[_]bool{false}**M;
    for(0..on)|i|{const e=order[i];if(join(&parent,&ranks,g.edges[e].u,g.edges[e].v)){tree[e]=true;}}
    const terminal_root=find(&parent,g.terminals[0]);for(1..g.k)|i|{if(find(&parent,g.terminals[i])!=terminal_root)return null;}
    var is_term=[_]bool{false}**N;for(0..g.k)|i|is_term[g.terminals[i]]=true;var degree=[_]usize{0}**N;
    for(0..g.m)|e|{if(tree[e]){degree[g.edges[e].u]+=1;degree[g.edges[e].v]+=1;}}
    var queue=[_]usize{0}**N;var queued=[_]bool{false}**N;var head:usize=0;var tail:usize=0;
    for(0..g.n)|v|{if(!is_term[v] and degree[v]<=1){queue[tail]=v;tail+=1;queued[v]=true;}}
    while(head<tail){const u=queue[head];head+=1;if(degree[u]>1)continue;for(0..g.m)|e|{if(tree[e] and (g.edges[e].u==u or g.edges[e].v==u)){tree[e]=false;const v=if(g.edges[e].u==u)g.edges[e].v else g.edges[e].u;degree[u]-=1;degree[v]-=1;if(!is_term[v] and degree[v]<=1 and !queued[v]){queue[tail]=v;tail+=1;queued[v]=true;}}}}
    var answer=Answer{.cost=0,.edges=[_]usize{0}**M,.count=0};for(0..g.m)|e|if(tree[e]){answer.edges[answer.count]=e;answer.count+=1;answer.cost+=g.edges[e].w;};
    if(answer.count==0 or answer.count>g.n-1)return null;return answer;
}
fn put(output: [*c]u8, at: usize, value: i64) void { const bits: u64=@bitCast(value); for(0..8)|b| output[at+b]=@truncate(bits >> @intCast(8*b)); }

export fn steiner_tree_mehlhorn_voronoi_mst(input: [*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    const g=parse(input,length) orelse return -1;const answer=solve(g) orelse return -1;const bytes=(2+answer.count)*8;
    if(output==null or capacity<bytes or bytes>MAX_OUTPUT)return -2;put(output,0,answer.cost);put(output,8,@intCast(answer.count));for(0..answer.count)|i|put(output,16+i*8,@intCast(answer.edges[i]));return @intCast(bytes);
}
