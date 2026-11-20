module steiner_tree_mehlhorn_voronoi_mst

const max_n=8
const max_m=14
const max_input=54
const max_output=72
const inf=i64(4611686018427387903)
struct Edge { u int; v int; w i64 }
struct Candidate { a int; b int; left int; right int; edge int; w i64 }

fn find_root(mut parent [max_n]int,x0 int) int {
 mut x:=x0
 for parent[x]!=x { parent[x]=parent[parent[x]];x=parent[x] }
 return x
}
fn join(mut parent [max_n]int,mut rank [max_n]int,a0 int,b0 int) bool {
 mut a:=find_root(mut parent,a0);mut b:=find_root(mut parent,b0)
 if a==b{return false};if rank[a]<rank[b]{t:=a;a=b;b=t};parent[b]=a;if rank[a]==rank[b]{rank[a]++};return true
}
fn candidate_before(a Candidate,b Candidate) bool {
 if a.w!=b.w{return a.w<b.w};if a.a!=b.a{return a.a<b.a};if a.b!=b.b{return a.b<b.b};if a.left!=b.left{return a.left<b.left};if a.right!=b.right{return a.right<b.right};return a.edge<b.edge
}
fn put_i64(mut output &u8,offset int,value i64){bits:=u64(value);for b in 0..8{unsafe{output[offset+b]=u8((bits>>(8*b))&255)}}}

@[export:'steiner_tree_mehlhorn_voronoi_mst']
pub fn steiner_tree_mehlhorn_voronoi_mst(input &i64,length usize,mut output &u8,capacity usize)i64{
 if input==nil||length<3||length>max_input{return -1};n0:=unsafe{input[0]};m0:=unsafe{input[1]};k0:=unsafe{input[2]};if n0<2||n0>max_n||m0<1||m0>max_m||k0<2||k0>n0{return -1}
 n:=int(n0);m:=int(m0);k:=int(k0);if length<usize(3+k+3*m){return -1}
 mut terminals:=[max_n]int{};mut is_term:=[max_n]bool{};mut at:=3
 for i in 0..k{t:=unsafe{input[at]};at++;if t<0||t>=n0||is_term[int(t)]{return -1};terminals[i]=int(t);is_term[int(t)]=true}
 mut edges:=[max_m]Edge{};mut pairs:=[max_n*max_n]bool{}
 for e in 0..m{u0:=unsafe{input[at]};v0:=unsafe{input[at+1]};w:=unsafe{input[at+2]};at+=3;if u0<0||u0>=v0||v0>=n0||w<1||w>9{return -1};u:=int(u0);v:=int(v0);ix:=u*max_n+v;if pairs[ix]{return -1};pairs[ix]=true;edges[e]=Edge{u,v,w}}
 if at!=int(length){return -1}
 mut seen:=[max_n]bool{};mut q:=[max_n]int{};mut head:=0;mut tail:=0;seen[0]=true;q[tail]=0;tail++
 for head<tail{x:=q[head];head++;for e in 0..m{mut y:=-1;if edges[e].u==x{y=edges[e].v}else if edges[e].v==x{y=edges[e].u};if y>=0&&!seen[y]{seen[y]=true;q[tail]=y;tail++}}};for v in 0..n{if !seen[v]{return -1}}
 mut dist:=[max_n]i64{};mut owner:=[max_n]int{};mut pred:=[max_n]int{};mut pred_edge:=[max_n]int{};mut settled:=[max_n]bool{}
 for v in 0..n{dist[v]=inf;owner[v]=n;pred[v]=-1;pred_edge[v]=-1};for i in 0..k{t:=terminals[i];dist[t]=0;owner[t]=t}
 for _ in 0..n{mut u:=-1;for v in 0..n{if !settled[v]&&(u<0||dist[v]<dist[u]||(dist[v]==dist[u]&&(owner[v]<owner[u]||(owner[v]==owner[u]&&v<u)))){u=v}};if u<0||dist[u]==inf{break};settled[u]=true
  for e in 0..m{mut v:=-1;if edges[e].u==u{v=edges[e].v}else if edges[e].v==u{v=edges[e].u};if v<0{continue};nd:=dist[u]+edges[e].w;if nd<dist[v]||(nd==dist[v]&&owner[u]<owner[v]){dist[v]=nd;owner[v]=owner[u];pred[v]=u;pred_edge[v]=e}else if nd==dist[v]&&owner[u]==owner[v]&&!settled[v]&&(pred[v]<0||u<pred[v]||(u==pred[v]&&e<pred_edge[v])){pred[v]=u;pred_edge[v]=e}}
 }
 for v in 0..n{if dist[v]==inf||owner[v]==n{return -1}}
 mut has:=[max_n*max_n]bool{};mut best:=[max_n*max_n]Candidate{}
 for e in 0..m{edge:=edges[e];mut a:=owner[edge.u];mut b:=owner[edge.v];if a==b{continue};mut left:=edge.u;mut right:=edge.v;if a>b{a,b=b,a;left,right=edge.v,edge.u};c:=Candidate{a,b,left,right,e,dist[edge.u]+edge.w+dist[edge.v]};ix:=a*max_n+b;if !has[ix]||candidate_before(c,best[ix]){has[ix]=true;best[ix]=c}}
 mut candidates:=[max_m]Candidate{};mut cn:=0;for a in 0..n{for b in a+1..n{ix:=a*max_n+b;if has[ix]{candidates[cn]=best[ix];cn++}}}
 for i in 1..cn{x:=candidates[i];mut j:=i;for j>0&&candidate_before(x,candidates[j-1]){candidates[j]=candidates[j-1];j--};candidates[j]=x}
 mut parent:=[max_n]int{};mut rank:=[max_n]int{};for v in 0..n{parent[v]=v};mut chosen:=[max_n]int{};mut ch:=0;for i in 0..cn{if ch==k-1{break};if join(mut parent,mut rank,candidates[i].a,candidates[i].b){chosen[ch]=i;ch++}};if ch!=k-1{return -1}
 mut used:=[max_m]bool{};for i in 0..ch{c:=candidates[chosen[i]];used[c.edge]=true;mut x:=c.left;for x!=c.a{if pred_edge[x]<0{return -1};used[pred_edge[x]]=true;x=pred[x]};x=c.right;for x!=c.b{if pred_edge[x]<0{return -1};used[pred_edge[x]]=true;x=pred[x]}}
 mut order:=[max_m]int{};mut on:=0;for e in 0..m{if used[e]{order[on]=e;on++}};for i in 1..on{x:=order[i];mut j:=i;for j>0&&(edges[x].w<edges[order[j-1]].w||(edges[x].w==edges[order[j-1]].w&&x<order[j-1])){order[j]=order[j-1];j--};order[j]=x}
 for v in 0..n{parent[v]=v;rank[v]=0};mut tree:=[max_m]bool{};for i in 0..on{e:=order[i];if join(mut parent,mut rank,edges[e].u,edges[e].v){tree[e]=true}};r:=find_root(mut parent,terminals[0]);for i in 1..k{if find_root(mut parent,terminals[i])!=r{return -1}}
 mut degree:=[max_n]int{};for e in 0..m{if tree[e]{degree[edges[e].u]++;degree[edges[e].v]++}};mut leaves:=[max_n]int{};mut queued:=[max_n]bool{};head=0;tail=0;for v in 0..n{if !is_term[v]&&degree[v]<=1{leaves[tail]=v;tail++;queued[v]=true}}
 for head<tail{u:=leaves[head];head++;if degree[u]>1{continue};for e in 0..m{if tree[e]&&(edges[e].u==u||edges[e].v==u){tree[e]=false;mut v:=edges[e].u;if v==u{v=edges[e].v};degree[u]--;degree[v]--;if !is_term[v]&&degree[v]<=1&&!queued[v]{leaves[tail]=v;tail++;queued[v]=true}}}}
 mut result:=[max_m]int{};mut count:=0;mut cost:=i64(0);for e in 0..m{if tree[e]{result[count]=e;count++;cost+=edges[e].w}};if count==0||count>n-1{return -1}
 bytes:=(2+count)*8;if output==nil||capacity<usize(bytes)||bytes>max_output{return -2};put_i64(mut output,0,cost);put_i64(mut output,8,i64(count));for i in 0..count{put_i64(mut output,16+i*8,i64(result[i]))};return i64(bytes)
}
