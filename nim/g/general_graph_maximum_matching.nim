type I12=array[12,int]
type B12=array[12,bool]
type Adj=array[144,bool]
proc put64(out:ptr UncheckedArray[uint8],x:int64)=
  let b=cast[uint64](x)
  for i in 0..<8:out[i]=uint8((b shr (8*i)) and 255)
proc lca(n:int,match:var I12,parent:var I12,base:var I12,a0,b0:int):int=
  var seen:B12;var a=a0;var b=b0
  while true:
    a=base[a];seen[a]=true
    if match[a]<0:break
    a=parent[match[a]]
  while true:
    b=base[b]
    if seen[b]:return b
    b=parent[match[b]]
proc markPath(match:var I12,parent:var I12,base:var I12,blossom:var B12,v0,b,child0:int)=
  var v=v0;var child=child0
  while base[v]!=b:
    blossom[base[v]]=true;blossom[base[match[v]]]=true
    parent[v]=child;child=match[v];v=parent[match[v]]
proc findPath(n:int,adj:Adj,match:var I12,parent:var I12,base:var I12,root:int):bool=
  var used:B12;var queue:I12;var head=0;var tail=0
  for i in 0..<n:parent[i] = -1;base[i]=i
  queue[tail]=root;inc tail;used[root]=true
  while head<tail:
    let v=queue[head];inc head
    for u in 0..<n:
      if not adj[v*12+u] or base[v]==base[u] or match[v]==u:continue
      if u==root or (match[u]>=0 and parent[match[u]]>=0):
        let cur=lca(n,match,parent,base,v,u);var blossom:B12
        markPath(match,parent,base,blossom,v,cur,u);markPath(match,parent,base,blossom,u,cur,v)
        for i in 0..<n:
          if blossom[base[i]]:
            base[i]=cur
            if not used[i]:used[i]=true;queue[tail]=i;inc tail
      elif parent[u]<0:
        parent[u]=v
        if match[u]<0:
          var x=u
          while x>=0:
            let pv=parent[x];let next=if pv>=0:match[pv] else: -1
            if pv>=0:match[x]=pv;match[pv]=x
            x=next
          return true
        let mate=match[u];used[mate]=true;queue[tail]=mate;inc tail
  false
proc general_graph_maximum_matching*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"general_graph_maximum_matching".}=
  if input==nil or length<2 or length>134:return -1
  let n0=input[0];let m0=input[1]
  if n0<2 or n0>12 or m0<0 or m0>n0*(n0-1) div 2 or int64(length)!=2+2*m0:return -1
  let n=int(n0);let m=int(m0);var adj:Adj
  for e in 0..<m:
    let u0=input[2+2*e];let v0=input[3+2*e]
    if u0<0 or v0<=u0 or v0>=n0:return -1
    let u=int(u0);let v=int(v0);if adj[u*12+v]:return -1
    adj[u*12+v]=true;adj[v*12+u]=true
  var match:I12;var parent:I12;var base:I12
  for i in 0..<n:match[i] = -1
  for i in 0..<n:if match[i]<0:discard findPath(n,adj,match,parent,base,i)
  var count=0'i64;for i in 0..<n:if match[i]>i:inc count
  if output==nil or capacity<8:return -2
  put64(output,count);8
