const N: usize = 8;
const M: usize = 18;
const F: usize = 12;
const MAX_INPUT: usize = 93;
const FLOW_NODES: usize = 18;

fn connected(adj: *const [N][N]bool, n: usize, removed: isize) bool {
    const start: usize = if (removed == 0) 1 else 0;
    var seen = [_]bool{false} ** N;
    var stack = [_]usize{0} ** N;
    var top: usize = 1;
    var count: usize = 0;
    seen[start] = true;
    stack[0] = start;
    while (top > 0) {
        top -= 1;
        const u = stack[top];
        count += 1;
        for (0..n) |v| {
            if (@as(isize, @intCast(v)) != removed and adj[u][v] and !seen[v]) {
                seen[v] = true;
                stack[top] = v;
                top += 1;
            }
        }
    }
    return count == n - @as(usize, @intCast(if (removed >= 0) 1 else 0));
}

fn threeOuterPaths(adj: *const [N][N]bool, outer: *const [N]bool, n: usize, root: usize) bool {
    var residual = [_][FLOW_NODES]i32{[_]i32{0} ** FLOW_NODES} ** FLOW_NODES;
    const source = 2 * n;
    const sink = source + 1;
    const nodes = sink + 1;
    for (0..n) |v| if (v != root) { residual[2 * v][2 * v + 1] = 1; };
    for (0..n) |u| for (u + 1..n) |v| {
        if (!adj[u][v]) continue;
        if (u == root) residual[source][2 * v] += 1 else if (v == root) residual[source][2 * u] += 1 else {
            residual[2 * u + 1][2 * v] += 1;
            residual[2 * v + 1][2 * u] += 1;
        }
    };
    for (0..n) |v| if (outer[v] and v != root) { residual[2 * v + 1][sink] += 1; };
    for (0..3) |_| {
        var parent = [_]isize{-1} ** FLOW_NODES;
        var queue = [_]usize{0} ** FLOW_NODES;
        var head: usize = 0;
        var tail: usize = 1;
        parent[source] = @intCast(source);
        queue[0] = source;
        while (head < tail and parent[sink] < 0) {
            const u = queue[head];
            head += 1;
            for (0..nodes) |v| {
                if (residual[u][v] > 0 and parent[v] < 0) {
                    parent[v] = @intCast(u);
                    queue[tail] = v;
                    tail += 1;
                    if (v == sink) break;
                }
            }
        }
        if (parent[sink] < 0) return false;
        var v = sink;
        while (v != source) {
            const u: usize = @intCast(parent[v]);
            residual[u][v] -= 1;
            residual[v][u] += 1;
            v = u;
        }
    }
    return true;
}

fn conditionThree(inner: *const [N][N]bool, degree: *const [N]usize, n: usize) bool {
    var mask_size = [_]usize{0} ** (1 << N);
    for (1..(1 << n)) |mask| mask_size[mask] = mask_size[mask >> 1] + (mask & 1);
    for (0..n) |start| {
        var dp = [_][N]u8{[_]u8{255} ** N} ** (1 << N);
        dp[1 << start][start] = if (degree[start] >= 3) 1 else 0;
        for (0..(1 << n)) |mask| {
            if (mask & (1 << start) == 0) continue;
            for (start..n) |last| {
                const used = dp[mask][last];
                if (used == 255) continue;
                if (mask_size[mask] >= 3 and inner[last][start] and used < 3) return false;
                for (start + 1..n) |next| {
                    const bit = 1 << next;
                    if (mask & bit != 0 or !inner[last][next]) continue;
                    const next_mask = mask | bit;
                    const candidate: u8 = used + (if (degree[next] >= 3) 1 else 0);
                    if (candidate < dp[next_mask][next]) dp[next_mask][next] = candidate;
                }
            }
        }
    }
    return true;
}

pub export fn thomassen_convex_drawing_extendibility(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 5 or length > MAX_INPUT) return -1;
    const n0=input[0]; const m0=input[1]; const f0=input[2]; const outer0=input[3]; const sides0=input[4];
    if (n0 < 3 or n0 > N or m0 < n0 or m0 > M or m0 > 3*n0-6 or f0 < 2 or f0 > F or
        f0 != m0-n0+2 or outer0 < 0 or outer0 >= f0 or sides0 < 3 or sides0 > n0) return -1;
    const n: usize = @intCast(n0); const m: usize = @intCast(m0); const f: usize = @intCast(f0);
    const outer_id: usize = @intCast(outer0); const side_count: usize = @intCast(sides0);
    var adj = [_][N]bool{[_]bool{false} ** N} ** N;
    var edge_u = [_]usize{0} ** M; var edge_v = [_]usize{0} ** M;
    var p: usize = 5;
    for (0..m) |e| {
        if (p + 2 > length) return -1;
        const u0=input[p]; const v0=input[p+1]; p+=2;
        if (u0 < 0 or u0 >= v0 or v0 >= n0) return -1;
        const u: usize=@intCast(u0); const v: usize=@intCast(v0);
        if (adj[u][v] or (e > 0 and (u < edge_u[e-1] or (u == edge_u[e-1] and v <= edge_v[e-1])))) return -1;
        adj[u][v]=true; adj[v][u]=true; edge_u[e]=u; edge_v[e]=v;
    }
    var faces = [_][N]usize{[_]usize{0} ** N} ** F;
    var widths = [_]usize{0} ** F;
    var darts = [_][N]usize{[_]usize{0} ** N} ** N;
    for (0..f) |face| {
        if (p >= length) return -1;
        const w0=input[p]; p+=1;
        if (w0 < 3 or w0 > n0 or p + @as(usize,@intCast(w0)) > length) return -1;
        widths[face]=@intCast(w0);
        var row=[_]bool{false} ** N;
        for (0..widths[face]) |i| {
            const x0=input[p];p+=1;
            if(x0<0 or x0>=n0 or row[@as(usize,@intCast(x0))])return -1;
            const x:usize=@intCast(x0);row[x]=true;faces[face][i]=x;
        }
        for (0..widths[face]) |i| {const u=faces[face][i];const v=faces[face][(i+1)%widths[face]];if(!adj[u][v])return -1;darts[u][v]+=1;}
    }
    if (p+side_count!=length) return -1;
    var apex=[_]usize{0} ** N;
    for(0..side_count)|i|{const pos=input[p];p+=1;if(pos<0 or pos>=@as(i64,@intCast(widths[outer_id])) or (i>0 and pos<=@as(i64,@intCast(apex[i-1]))))return -1;apex[i]=@intCast(pos);}
    for(0..m)|e|if(darts[edge_u[e]][edge_v[e]]!=1 or darts[edge_v[e]][edge_u[e]]!=1)return -1;
    if(!connected(&adj,n,-1))return -1;for(0..n)|v|if(!connected(&adj,n,@intCast(v)))return -1;
    var link_adj=[_][N][N]bool{[_][N]bool{[_]bool{false} ** N} ** N} ** N;
    var link_degree=[_][N]usize{[_]usize{0} ** N} ** N;
    for(0..f)|face|for(0..widths[face])|i|{const center=faces[face][i];const before=faces[face][(i+widths[face]-1)%widths[face]];const after=faces[face][(i+1)%widths[face]];if(before==after)return -1;link_adj[center][before][after]=true;link_adj[center][after][before]=true;link_degree[center][before]+=1;link_degree[center][after]+=1;};
    var outer_v=[_]bool{false} ** N;var outer_e=[_][N]bool{[_]bool{false} ** N} ** N;
    for(0..widths[outer_id])|i|{const u=faces[outer_id][i];const v=faces[outer_id][(i+1)%widths[outer_id]];outer_v[u]=true;outer_e[u][v]=true;outer_e[v][u]=true;}
    for(0..n)|center|{var seed:?usize=null;var incident:usize=0;for(0..n)|v|{if(adj[center][v]){if(link_degree[center][v]!=2)return -1;if(seed==null)seed=v;incident+=1;}else if(link_degree[center][v]!=0)return -1;}const start=seed orelse return -1;var seen=[_]bool{false} ** N;var stack=[_]usize{0} ** N;var top:usize=1;var reached:usize=0;seen[start]=true;stack[0]=start;while(top>0){top-=1;const v=stack[top];reached+=1;for(0..n)|w|{if(link_adj[center][v][w] and !seen[w]){seen[w]=true;stack[top]=w;top+=1;}}}if(reached!=incident)return -1;}
    var face_a=[_]usize{0} ** M;var face_b=[_]usize{0} ** M;var face_use=[_]usize{0} ** M;
    for(0..f)|face|for(0..widths[face])|i|{const u=faces[face][i];const v=faces[face][(i+1)%widths[face]];const lo=@min(u,v);const hi=@max(u,v);var found:?usize=null;for(0..m)|e|if(edge_u[e]==lo and edge_v[e]==hi){found=e;break;};const e=found orelse return -1;if(face_use[e]>=2)return -1;if(face_use[e]==0){face_a[e]=face;}else{face_b[e]=face;}face_use[e]+=1;};
    for(0..m)|e|if(face_use[e]!=2 or face_a[e]==face_b[e])return -1;
    var sides=[_][N]bool{[_]bool{false} ** N} ** N;
    for(0..side_count)|s|{var at=apex[s];const end=apex[(s+1)%side_count];while(true){sides[s][faces[outer_id][at]]=true;if(at==end)break;at=(at+1)%widths[outer_id];}}
    var degree=[_]usize{0} ** N;for(0..n)|u|for(0..n)|v|{if(adj[u][v])degree[u]+=1;};
    for(0..n)|root|if(!outer_v[root] and degree[root]>=3 and !threeOuterPaths(&adj,&outer_v,n,root))return 0;
    var seen_inner=[_]bool{false} ** N;
    for(0..n)|seed|{if(outer_v[seed] or seen_inner[seed])continue;var border=[_]bool{false} ** N;var stack=[_]usize{0} ** N;var top:usize=1;stack[0]=seed;seen_inner[seed]=true;while(top>0){top-=1;const u=stack[top];for(0..n)|v|{if(!adj[u][v])continue;if(outer_v[v]){border[v]=true;}else if(!seen_inner[v]){seen_inner[v]=true;stack[top]=v;top+=1;}}}for(0..side_count)|s|{var nonempty=false;var contained=true;for(0..n)|v|{if(border[v]){nonempty=true;if(!sides[s][v])contained=false;}}if(nonempty and contained)return 0;}}
    for(0..m)|e|{const u=edge_u[e];const v=edge_v[e];if(!outer_e[u][v])for(0..side_count)|s|{if(sides[s][u] and sides[s][v])return 0;};}
    var inner=[_][N]bool{[_]bool{false} ** N} ** N;for(0..m)|e|{const u=edge_u[e];const v=edge_v[e];if(!outer_e[u][v]){inner[u][v]=true;inner[v][u]=true;}}
    return if(conditionThree(&inner,&degree,n)) 1 else 0;
}
