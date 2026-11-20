package thomassen_convex_drawing_extendibility

import "core:c"

N :: 8
M :: 18
F :: 12
INPUT_MAX :: 93
FLOW_NODES :: 18
STATES :: 256

connected :: proc "contextless" (adj: [N][N]bool, n, removed: int) -> bool {
    start := 0
    if removed == 0 { start = 1 }
    var seen: [N]bool
    var stack: [N]int
    top, count := 1, 0
    seen[start] = true; stack[0] = start
    for top > 0 {
        top -= 1
        u := stack[top]
        count += 1
        for v := 0; v < n; v += 1 {
            if v != removed && adj[u][v] && !seen[v] { seen[v] = true; stack[top] = v; top += 1 }
        }
    }
    return count == n - (if removed >= 0 { 1 } else { 0 })
}

three_outer_paths :: proc "contextless" (adj: [N][N]bool, outer: [N]bool, n, root: int) -> bool {
    var residual: [FLOW_NODES][FLOW_NODES]int
    source, sink := 2*n, 2*n+1
    nodes := sink + 1
    for v := 0; v < n; v += 1 { if v != root { residual[2*v][2*v+1] = 1 } }
    for u := 0; u < n; u += 1 { for v := u+1; v < n; v += 1 {
        if !adj[u][v] { continue }
        if u == root { residual[source][2*v] += 1 }
        else if v == root { residual[source][2*u] += 1 }
        else { residual[2*u+1][2*v] += 1; residual[2*v+1][2*u] += 1 }
    }}
    for v := 0; v < n; v += 1 { if outer[v] && v != root { residual[2*v+1][sink] += 1 } }
    for flow := 0; flow < 3; flow += 1 {
        var parent: [FLOW_NODES]int
        var queue: [FLOW_NODES]int
        for v := 0; v < nodes; v += 1 { parent[v] = -1 }
        parent[source] = source; queue[0] = source
        head, tail := 0, 1
        for head < tail && parent[sink] < 0 {
            u := queue[head]; head += 1
            for v := 0; v < nodes; v += 1 {
                if residual[u][v] > 0 && parent[v] < 0 {
                    parent[v] = u; queue[tail] = v; tail += 1
                    if v == sink { break }
                }
            }
        }
        if parent[sink] < 0 { return false }
        v := sink
        for v != source { u := parent[v]; residual[u][v] -= 1; residual[v][u] += 1; v = u }
    }
    return true
}

condition_three :: proc "contextless" (inner: [N][N]bool, degree: [N]int, n: int) -> bool {
    var mask_size: [STATES]int
    for mask := 1; mask < (1<<n); mask += 1 { mask_size[mask] = mask_size[mask>>1] + (mask & 1) }
    for start := 0; start < n; start += 1 {
        var dp: [STATES][N]u8
        for mask := 0; mask < STATES; mask += 1 { for last := 0; last < N; last += 1 { dp[mask][last] = 255 } }
        dp[1<<start][start] = 0
        if degree[start] >= 3 { dp[1<<start][start] = 1 }
        for mask := 0; mask < (1<<n); mask += 1 {
            if mask & (1<<start) == 0 { continue }
            for last := start; last < n; last += 1 {
                used := dp[mask][last]
                if used == 255 { continue }
                if mask_size[mask] >= 3 && inner[last][start] && used < 3 { return false }
                for next := start+1; next < n; next += 1 {
                    bit := 1<<next
                    if mask & bit != 0 || !inner[last][next] { continue }
                    candidate := used
                    if degree[next] >= 3 { candidate += 1 }
                    next_mask := mask | bit
                    if candidate < dp[next_mask][next] { dp[next_mask][next] = candidate }
                }
            }
        }
    }
    return true
}

@(export)
thomassen_convex_drawing_extendibility :: proc "c" (input: [^]i64, input_length: c.size_t) -> i64 {
    if input == nil || input_length < 5 || input_length > INPUT_MAX { return -1 }
    n0,m0,f0,outer0,sides0 := input[0],input[1],input[2],input[3],input[4]
    if n0 < 3 || n0 > N || m0 < n0 || m0 > M || m0 > 3*n0-6 || f0 < 2 || f0 > F ||
       f0 != m0-n0+2 || outer0 < 0 || outer0 >= f0 || sides0 < 3 || sides0 > n0 { return -1 }
    n,m,f,outer_id,side_count := int(n0),int(m0),int(f0),int(outer0),int(sides0)
    var adj: [N][N]bool
    var edge_u,edge_v: [M]int
    cursor := 5
    for e := 0; e < m; e += 1 {
        if cursor+2 > int(input_length) { return -1 }
        u0,v0 := input[cursor],input[cursor+1]; cursor += 2
        if u0 < 0 || u0 >= v0 || v0 >= n0 { return -1 }
        u,v := int(u0),int(v0)
        if adj[u][v] || (e>0 && (u<edge_u[e-1] || (u==edge_u[e-1] && v<=edge_v[e-1]))) { return -1 }
        adj[u][v],adj[v][u]=true,true; edge_u[e],edge_v[e]=u,v
    }
    var face: [F][N]int
    var width: [F]int
    var darts: [N][N]int
    for g := 0; g < f; g += 1 {
        if cursor >= int(input_length) { return -1 }
        w0 := input[cursor]; cursor += 1
        if w0 < 3 || w0 > n0 || cursor+int(w0)>int(input_length) { return -1 }
        width[g]=int(w0)
        var row: [N]bool
        for i:=0;i<width[g];i+=1 {
            x0:=input[cursor];cursor+=1
            if x0<0||x0>=n0{return -1};x:=int(x0)
            if row[x]{return -1};row[x]=true;face[g][i]=x
        }
        for i:=0;i<width[g];i+=1 {u,v:=face[g][i],face[g][(i+1)%width[g]];if !adj[u][v]{return -1};darts[u][v]+=1}
    }
    if cursor+side_count!=int(input_length){return -1}
    var apex:[N]int
    for i:=0;i<side_count;i+=1 {pos:=input[cursor];cursor+=1;if pos<0||pos>=i64(width[outer_id])||(i>0&&pos<=i64(apex[i-1])){return -1};apex[i]=int(pos)}
    for e:=0;e<m;e+=1{if darts[edge_u[e]][edge_v[e]]!=1||darts[edge_v[e]][edge_u[e]]!=1{return -1}}
    if !connected(adj,n,-1){return -1};for v:=0;v<n;v+=1{if !connected(adj,n,v){return -1}}
    var link_adj:[N][N][N]bool;var link_degree:[N][N]int
    for g:=0;g<f;g+=1{for i:=0;i<width[g];i+=1{center:=face[g][i];before:=face[g][(i+width[g]-1)%width[g]];after:=face[g][(i+1)%width[g]];if before==after{return -1};link_adj[center][before][after]=true;link_adj[center][after][before]=true;link_degree[center][before]+=1;link_degree[center][after]+=1}}
    for center:=0;center<n;center+=1{seed,incident:=-1,0;for v:=0;v<n;v+=1{if adj[center][v]{if link_degree[center][v]!=2{return -1};if seed<0{seed=v};incident+=1}else if link_degree[center][v]!=0{return -1}};if seed<0{return -1};var seen:[N]bool;var stack:[N]int;top,reached:=1,0;seen[seed]=true;stack[0]=seed;for top>0{top-=1;v:=stack[top];reached+=1;for w:=0;w<n;w+=1{if link_adj[center][v][w]&&!seen[w]{seen[w]=true;stack[top]=w;top+=1}}};if reached!=incident{return -1}}
    var outer_v:[N]bool;var outer_e:[N][N]bool
    for i:=0;i<width[outer_id];i+=1{u,v:=face[outer_id][i],face[outer_id][(i+1)%width[outer_id]];outer_v[u]=true;outer_e[u][v]=true;outer_e[v][u]=true}
    var fa,fb,fc:[M]int
    for g:=0;g<f;g+=1{for i:=0;i<width[g];i+=1{u,v:=face[g][i],face[g][(i+1)%width[g]];lo,hi:=u,v;if lo>hi{lo,hi=hi,lo};found:=-1;for e:=0;e<m;e+=1{if edge_u[e]==lo&&edge_v[e]==hi{found=e;break}};if found<0||fc[found]>=2{return -1};if fc[found]==0{fa[found]=g}else{fb[found]=g};fc[found]+=1}}
    for e:=0;e<m;e+=1{if fc[e]!=2||fa[e]==fb[e]{return -1}}
    var sides:[N][N]bool
    for s:=0;s<side_count;s+=1{at,end:=apex[s],apex[(s+1)%side_count];for{ sides[s][face[outer_id][at]]=true;if at==end{break};at=(at+1)%width[outer_id]}}
    var degree:[N]int
    for u:=0;u<n;u+=1{for v:=0;v<n;v+=1{if adj[u][v]{degree[u]+=1}}}
    for root:=0;root<n;root+=1{if !outer_v[root]&&degree[root]>=3&&!three_outer_paths(adj,outer_v,n,root){return 0}}
    var seen_inner:[N]bool
    for seed:=0;seed<n;seed+=1{if outer_v[seed]||seen_inner[seed]{continue};var border:[N]bool;var stack:[N]int;top:=1;stack[0]=seed;seen_inner[seed]=true;for top>0{top-=1;u:=stack[top];for v:=0;v<n;v+=1{if !adj[u][v]{continue};if outer_v[v]{border[v]=true}else if !seen_inner[v]{seen_inner[v]=true;stack[top]=v;top+=1}}};for s:=0;s<side_count;s+=1{nonempty,contained:=false,true;for v:=0;v<n;v+=1{if border[v]{nonempty=true;if !sides[s][v]{contained=false}}};if nonempty&&contained{return 0}}}
    for e:=0;e<m;e+=1{u,v:=edge_u[e],edge_v[e];if !outer_e[u][v]{for s:=0;s<side_count;s+=1{if sides[s][u]&&sides[s][v]{return 0}}}}
    var inner:[N][N]bool
    for e:=0;e<m;e+=1{u,v:=edge_u[e],edge_v[e];if !outer_e[u][v]{inner[u][v]=true;inner[v][u]=true}}
    if condition_three(inner,degree,n){return 1};return 0
}
