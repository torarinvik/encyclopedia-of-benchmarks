const MaxN=8
const MaxM=28
const MaxInput=59
proc put(o:ptr UncheckedArray[uint8],at:int,x:int64)=
  let b=cast[uint64](x)
  for i in 0..<8:o[at+i]=uint8((b shr (8*i)) and 255)
proc connected(n,m:int,u,v:array[MaxM,int],on:array[MaxM,bool],skip:int):bool=
  var seen:array[MaxN,bool]
  var queue:array[MaxN,int]
  var head=0;var tail=1;queue[0]=0;seen[0]=true
  while head<tail:
    let a=queue[head];inc head
    for e in 0..<m:
      if not on[e] or e==skip:continue
      var b=MaxN
      if u[e]==a:b=v[e]
      elif v[e]==a:b=u[e]
      if b<MaxN and not seen[b]:seen[b]=true;queue[tail]=b;inc tail
  for i in 0..<n:if not seen[i]:return false
  true
proc edgeConnected(n,m:int,u,v:array[MaxM,int],on:array[MaxM,bool]):bool=
  if not connected(n,m,u,v,on,-1):return false
  for e in 0..<m:if on[e] and not connected(n,m,u,v,on,e):return false
  true
proc two_edge_connected_spanning_subgraph_greedy*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"two_edge_connected_spanning_subgraph_greedy".}=
  if input.isNil or length<2 or length>csize_t(MaxInput):return -1
  let n0=input[0];let m0=input[1]
  if n0<3 or n0>8 or m0<3 or m0>28 or int(length)!=2+2*int(m0):return -1
  let n=int(n0);let m=int(m0)
  var u,v:array[MaxM,int];var on:array[MaxM,bool]
  for i in 0..<m:
    let a=input[2+2*i];let b=input[3+2*i]
    if a<0 or a>=b or b>=n0:return -1
    u[i]=int(a);v[i]=int(b);on[i]=true
    for j in 0..<i:if u[i]==u[j] and v[i]==v[j]:return -1
  if not edgeConnected(n,m,u,v,on):return -1
  for e in 0..<m:on[e]=false;if not edgeConnected(n,m,u,v,on):on[e]=true
  var count=0
  for e in 0..<m:if on[e]:inc count
  let bytes=8*(1+2*count)
  if output.isNil or capacity<csize_t(bytes):return -2
  put(output,0,int64(count));var at=8
  for a in 0..<n:for b in a+1..<n:for e in 0..<m:
    if on[e] and u[e]==a and v[e]==b:put(output,at,int64(a));put(output,at+8,int64(b));at+=16
  int64(bytes)
