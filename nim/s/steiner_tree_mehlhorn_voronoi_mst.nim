const MaxN=8;const MaxM=14;const MaxInput=54;const MaxOutput=72;const Inf=int64.high div 4
type Edge=object
  u,v:int
  w:int64
type Candidate=object
  a,b,left,right,edge:int
  w:int64
type Graph=object
  n,m,k:int
  terminals:array[MaxN,int]
  edges:array[MaxM,Edge]

proc findRoot(parent:var array[MaxN,int],x0:int):int=
  var x=x0
  while parent[x]!=x:
    parent[x]=parent[parent[x]]
    x=parent[x]
  x
proc join(parent:var array[MaxN,int],rank:var array[MaxN,int],a0,b0:int):bool=
  var a=findRoot(parent,a0);var b=findRoot(parent,b0)
  if a==b:return false
  if rank[a]<rank[b]:swap(a,b)
  parent[b]=a
  if rank[a]==rank[b]:inc rank[a]
  true
proc candidateBefore(a,b:Candidate):bool=
  if a.w!=b.w:return a.w<b.w
  if a.a!=b.a:return a.a<b.a
  if a.b!=b.b:return a.b<b.b
  if a.left!=b.left:return a.left<b.left
  if a.right!=b.right:return a.right<b.right
  a.edge<b.edge
proc parse(input:ptr UncheckedArray[int64],length:int):tuple[ok:bool,g:Graph]=
  var g:Graph
  if input==nil or length<3 or length>MaxInput:return (false,g)
  let n0=input[0];let m0=input[1];let k0=input[2]
  if n0<2 or n0>MaxN or m0<1 or m0>MaxM or k0<2 or k0>n0:return (false,g)
  g.n=int(n0);g.m=int(m0);g.k=int(k0)
  if length<3+g.k+3*g.m:return (false,g)
  var terms:array[MaxN,bool];var at=3
  for i in 0..<g.k:
    let t=input[at];inc at
    if t<0 or t>=n0 or terms[int(t)]:return (false,g)
    g.terminals[i]=int(t);terms[int(t)]=true
  var pairs:array[MaxN,array[MaxN,bool]]
  for e in 0..<g.m:
    let u=input[at];let v=input[at+1];let w=input[at+2];at+=3
    if u<0 or u>=v or v>=n0 or w<1 or w>9:return (false,g)
    if pairs[int(u)][int(v)]:return (false,g)
    pairs[int(u)][int(v)]=true;g.edges[e]=Edge(u:int(u),v:int(v),w:w)
  if at!=length:return (false,g)
  var seen:array[MaxN,bool];var q:array[MaxN,int];var head=0;var tail=0
  seen[0]=true;q[tail]=0;inc tail
  while head<tail:
    let u=q[head];inc head
    for e in 0..<g.m:
      let edge=g.edges[e];let v=if edge.u==u:edge.v elif edge.v==u:edge.u else:-1
      if v>=0 and not seen[v]:seen[v]=true;q[tail]=v;inc tail
  for v in 0..<g.n:if not seen[v]:return (false,g)
  (true,g)

proc solve(g:Graph):tuple[ok:bool,cost:int64,ids:array[MaxM,int],count:int]=
  var outp:tuple[ok:bool,cost:int64,ids:array[MaxM,int],count:int]=(false,0'i64,default(array[MaxM,int]),0)
  var dist:array[MaxN,int64];var owner:array[MaxN,int];var pred:array[MaxN,int];var predEdge:array[MaxN,int];var settled:array[MaxN,bool]
  for v in 0..<g.n:dist[v]=Inf;owner[v]=g.n;pred[v]= -1;predEdge[v]= -1
  for i in 0..<g.k:let t=g.terminals[i];dist[t]=0;owner[t]=t
  for step in 0..<g.n:
    var u= -1
    for v in 0..<g.n:
      if not settled[v] and (u<0 or dist[v]<dist[u] or (dist[v]==dist[u] and (owner[v]<owner[u] or (owner[v]==owner[u] and v<u)))):u=v
    if u<0 or dist[u]==Inf:break
    settled[u]=true
    for e in 0..<g.m:
      let edge=g.edges[e];let v=if edge.u==u:edge.v elif edge.v==u:edge.u else:-1
      if v<0:continue
      let nd=dist[u]+edge.w
      if nd<dist[v] or (nd==dist[v] and owner[u]<owner[v]):dist[v]=nd;owner[v]=owner[u];pred[v]=u;predEdge[v]=e
      elif nd==dist[v] and owner[u]==owner[v] and not settled[v] and (pred[v]<0 or u<pred[v] or (u==pred[v] and e<predEdge[v])):pred[v]=u;predEdge[v]=e
  for v in 0..<g.n:if dist[v]==Inf or owner[v]==g.n:return outp
  var has:array[MaxN,array[MaxN,bool]];var best:array[MaxN,array[MaxN,Candidate]]
  for e in 0..<g.m:
    let edge=g.edges[e];var a=owner[edge.u];var b=owner[edge.v]
    if a==b:continue
    var left=edge.u;var right=edge.v
    if a>b:swap(a,b);left=edge.v;right=edge.u
    let c=Candidate(a:a,b:b,left:left,right:right,edge:e,w:dist[edge.u]+edge.w+dist[edge.v])
    if not has[a][b] or candidateBefore(c,best[a][b]):has[a][b]=true;best[a][b]=c
  var cand:array[MaxM,Candidate];var cn=0
  for a in 0..<g.n:for b in a+1..<g.n:if has[a][b]:cand[cn]=best[a][b];inc cn
  for i in 1..<cn:
    let x=cand[i];var j=i
    while j>0 and candidateBefore(x,cand[j-1]):cand[j]=cand[j-1];dec j
    cand[j]=x
  var parent:array[MaxN,int];var rank:array[MaxN,int]
  for v in 0..<g.n:parent[v]=v
  var chosen:array[MaxN,int];var ch=0
  for i in 0..<cn:
    if ch==g.k-1:break
    if join(parent,rank,cand[i].a,cand[i].b):chosen[ch]=i;inc ch
  if ch!=g.k-1:return outp
  var used:array[MaxM,bool]
  for i in 0..<ch:
    let c=cand[chosen[i]];used[c.edge]=true
    var x=c.left
    while x!=c.a:if predEdge[x]<0:return outp;used[predEdge[x]]=true;x=pred[x]
    x=c.right
    while x!=c.b:if predEdge[x]<0:return outp;used[predEdge[x]]=true;x=pred[x]
  var order:array[MaxM,int];var on=0
  for e in 0..<g.m:if used[e]:order[on]=e;inc on
  for i in 1..<on:
    let x=order[i];var j=i
    while j>0 and (g.edges[x].w<g.edges[order[j-1]].w or (g.edges[x].w==g.edges[order[j-1]].w and x<order[j-1])):order[j]=order[j-1];dec j
    order[j]=x
  for v in 0..<g.n:parent[v]=v;rank[v]=0
  var tree:array[MaxM,bool]
  for i in 0..<on:let e=order[i];if join(parent,rank,g.edges[e].u,g.edges[e].v):tree[e]=true
  let r=findRoot(parent,g.terminals[0]);for i in 1..<g.k:if findRoot(parent,g.terminals[i])!=r:return outp
  var isTerm:array[MaxN,bool];var degree:array[MaxN,int]
  for i in 0..<g.k:isTerm[g.terminals[i]]=true
  for e in 0..<g.m:if tree[e]:inc degree[g.edges[e].u];inc degree[g.edges[e].v]
  var q:array[MaxN,int];var queued:array[MaxN,bool];var head=0;var tail=0
  for v in 0..<g.n:if not isTerm[v] and degree[v]<=1:q[tail]=v;inc tail;queued[v]=true
  while head<tail:
    let u=q[head];inc head
    if degree[u]>1:continue
    for e in 0..<g.m:
      if tree[e] and (g.edges[e].u==u or g.edges[e].v==u):
        tree[e]=false;let v=if g.edges[e].u==u:g.edges[e].v else:g.edges[e].u;dec degree[u];dec degree[v]
        if not isTerm[v] and degree[v]<=1 and not queued[v]:q[tail]=v;inc tail;queued[v]=true
  outp.ok=true
  for e in 0..<g.m:if tree[e]:outp.ids[outp.count]=e;inc outp.count;outp.cost+=g.edges[e].w
  if outp.count==0 or outp.count>g.n-1:outp.ok=false
  outp

proc putI64(output:ptr UncheckedArray[uint8],at:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[at+b]=uint8((bits shr (8*b)) and 255'u64)

proc steiner_tree_mehlhorn_voronoi_mst*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"steiner_tree_mehlhorn_voronoi_mst".}=
  if input==nil or length>csize_t(MaxInput):return -1
  let parsed=parse(input,int(length))
  if not parsed.ok:return -1
  let answer=solve(parsed.g);if not answer.ok:return -1
  let bytes=(2+answer.count)*8
  if output==nil or capacity<csize_t(bytes) or bytes>MaxOutput:return -2
  putI64(output,0,answer.cost);putI64(output,8,int64(answer.count))
  for i in 0..<answer.count:putI64(output,16+i*8,int64(answer.ids[i]))
  int64(bytes)
