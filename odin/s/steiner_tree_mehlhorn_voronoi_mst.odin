package steiner_tree_mehlhorn_voronoi_mst
import "core:c"

N :: 8
M :: 14
MAX_INPUT :: 54
MAX_OUTPUT :: 72
INF :: i64(4611686018427387903)
Edge :: struct { u, v: int; w: i64 }
Candidate :: struct { a, b, left, right, edge: int; w: i64 }

root :: proc(parent: ^[N]int, x0: int) -> int {
    x := x0
    for parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x] }
    return x
}
join :: proc(parent: ^[N]int, rank: ^[N]int, a0, b0: int) -> bool {
    a := root(parent, a0); b := root(parent, b0)
    if a == b { return false }
    if rank[a] < rank[b] { a, b = b, a }
    parent[b] = a
    if rank[a] == rank[b] { rank[a] += 1 }
    return true
}
candidate_before :: proc(a, b: Candidate) -> bool {
    if a.w != b.w { return a.w < b.w }
    if a.a != b.a { return a.a < b.a }
    if a.b != b.b { return a.b < b.b }
    if a.left != b.left { return a.left < b.left }
    if a.right != b.right { return a.right < b.right }
    return a.edge < b.edge
}
put_i64 :: proc "contextless" (output: [^]u8, at: int, value: i64) {
    bits := u64(value)
    for b in 0..<8 { output[at+b] = u8(bits & 255); bits >>= 8 }
}

@(export)
steiner_tree_mehlhorn_voronoi_mst :: proc "c" (input: [^]i64, input_length: c.size_t,
                                                   output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 3 || input_length > MAX_INPUT do return -1
    n0,m0,k0 := input[0],input[1],input[2]
    if n0<2 || n0>N || m0<1 || m0>M || k0<2 || k0>n0 do return -1
    n,m,k := int(n0),int(m0),int(k0)
    if input_length < c.size_t(3+k+3*m) do return -1
    terminals: [N]int = {}
    is_terminal: [N]bool = {}
    at := 3
    for i in 0..<k {
        t0 := input[at]; at += 1
        if t0<0 || t0>=n0 || is_terminal[int(t0)] do return -1
        terminals[i]=int(t0);is_terminal[int(t0)]=true
    }
    edges: [M]Edge = {}
    pairs: [N][N]bool = {}
    for e in 0..<m {
        u0,v0,w0 := input[at],input[at+1],input[at+2];at+=3
        if u0<0 || u0>=v0 || v0>=n0 || w0<1 || w0>9 do return -1
        u,v := int(u0),int(v0)
        if pairs[u][v] do return -1
        pairs[u][v]=true;edges[e]=Edge{u,v,w0}
    }
    if at!=int(input_length) do return -1
    reached: [N]bool = {};queue: [N]int = {};head,tail:=0,0;reached[0]=true;queue[tail]=0;tail+=1
    for head<tail { u:=queue[head];head+=1;for e in 0..<m { v:=-1;if edges[e].u==u {v=edges[e].v} else if edges[e].v==u {v=edges[e].u};if v>=0&&!reached[v]{reached[v]=true;queue[tail]=v;tail+=1} } }
    for v in 0..<n { if !reached[v] do return -1 }
    dist: [N]i64 = {};owner,pred,pred_edge: [N]int = {};settled: [N]bool = {}
    for v in 0..<n {dist[v]=INF;owner[v]=n;pred[v]=-1;pred_edge[v]=-1}
    for i in 0..<k {t:=terminals[i];dist[t]=0;owner[t]=t}
    for _ in 0..<n {
        u:=-1
        for v in 0..<n {if !settled[v]&&(u<0||dist[v]<dist[u]||(dist[v]==dist[u]&&(owner[v]<owner[u]||(owner[v]==owner[u]&&v<u)))){u=v}}
        if u<0||dist[u]==INF {break};settled[u]=true
        for e in 0..<m {v:=-1;if edges[e].u==u{v=edges[e].v}else if edges[e].v==u{v=edges[e].u};if v<0{continue};nd:=dist[u]+edges[e].w
            if nd<dist[v]||(nd==dist[v]&&owner[u]<owner[v]){dist[v]=nd;owner[v]=owner[u];pred[v]=u;pred_edge[v]=e}
            else if nd==dist[v]&&owner[u]==owner[v]&&!settled[v]&&(pred[v]<0||u<pred[v]||(u==pred[v]&&e<pred_edge[v])){pred[v]=u;pred_edge[v]=e}
        }
    }
    for v in 0..<n {if dist[v]==INF||owner[v]==n do return -1}
    has: [N][N]bool = {};best: [N][N]Candidate = {}
    for e in 0..<m {u,v:=edges[e].u,edges[e].v;a,b:=owner[u],owner[v];if a==b{continue};left,right:=u,v;if a>b{a,b=b,a;left,right=v,u};c:=Candidate{a,b,left,right,e,dist[u]+edges[e].w+dist[v]};if !has[a][b]||candidate_before(c,best[a][b]){has[a][b]=true;best[a][b]=c}}
    candidates: [M]Candidate = {};cn:=0
    for a in 0..<n {for b in a+1..<n {if has[a][b]{candidates[cn]=best[a][b];cn+=1}}}
    for i in 1..<cn {x:=candidates[i];j:=i;for j>0&&candidate_before(x,candidates[j-1]){candidates[j]=candidates[j-1];j-=1};candidates[j]=x}
    parent,rank: [N]int = {};for v in 0..<n{parent[v]=v};chosen: [N]int = {};ch:=0
    for i in 0..<cn {if ch==k-1{break};if join(&parent,&rank,candidates[i].a,candidates[i].b){chosen[ch]=i;ch+=1}}
    if ch!=k-1 do return -1
    used: [M]bool = {}
    for i in 0..<ch {c:=candidates[chosen[i]];used[c.edge]=true;x:=c.left;for x!=c.a{if pred_edge[x]<0 do return -1;used[pred_edge[x]]=true;x=pred[x]};x=c.right;for x!=c.b{if pred_edge[x]<0 do return -1;used[pred_edge[x]]=true;x=pred[x]}}
    order: [M]int = {};on:=0;for e in 0..<m{if used[e]{order[on]=e;on+=1}}
    for i in 1..<on{x:=order[i];j:=i;for j>0&&(edges[x].w<edges[order[j-1]].w||(edges[x].w==edges[order[j-1]].w&&x<order[j-1])){order[j]=order[j-1];j-=1};order[j]=x}
    for v in 0..<n{parent[v]=v;rank[v]=0};tree: [M]bool = {};for i in 0..<on{e:=order[i];if join(&parent,&rank,edges[e].u,edges[e].v){tree[e]=true}}
    r:=root(&parent,terminals[0]);for i in 1..<k{if root(&parent,terminals[i])!=r do return -1}
    degree: [N]int = {};for e in 0..<m{if tree[e]{degree[edges[e].u]+=1;degree[edges[e].v]+=1}}
    leaves: [N]int = {};queued: [N]bool = {};head=0;tail=0;for v in 0..<n{if !is_terminal[v]&&degree[v]<=1{leaves[tail]=v;tail+=1;queued[v]=true}}
    for head<tail{u:=leaves[head];head+=1;if degree[u]>1{continue};for e in 0..<m{if tree[e]&&(edges[e].u==u||edges[e].v==u){tree[e]=false;v:=edges[e].u;if v==u{v=edges[e].v};degree[u]-=1;degree[v]-=1;if !is_terminal[v]&&degree[v]<=1&&!queued[v]{leaves[tail]=v;tail+=1;queued[v]=true}}}}
    result: [M]int = {};count:=0;cost:i64=0;for e in 0..<m{if tree[e]{result[count]=e;count+=1;cost+=edges[e].w}};if count==0||count>n-1 do return -1
    bytes:=c.size_t((2+count)*8);if output==nil||output_capacity<bytes||bytes>MAX_OUTPUT do return -2
    put_i64(output,0,cost);put_i64(output,8,i64(count));for i in 0..<count{put_i64(output,16+i*8,i64(result[i]))};return i64(bytes)
}
