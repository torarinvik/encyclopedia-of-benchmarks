proc putI64(out: ptr UncheckedArray[uint8], offset: int, x: int64) =
  let bits=cast[uint64](x)
  for b in 0..<8: out[offset+b]=uint8((bits shr (8*b)) and 255)

proc all_distances_sketch_bottom_k*(input: ptr UncheckedArray[int64], length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"all_distances_sketch_bottom_k".} =
  if input==nil or length<6 or length>104:return -1
  let n0=input[0];let m0=input[1];let k0=input[2];let s0=input[3]
  if n0<2 or n0>10 or m0<0 or m0>n0*(n0-1) or k0<1 or k0>n0 or s0<0 or s0>=n0:return -1
  let n=int(n0);let m=int(m0);let k=int(k0);let source=int(s0)
  if int(length)!=4+n+2*m:return -1
  var rank:array[10,int64];var used:array[10,bool]
  for i in 0..<n:
    let r=input[4+i];if r<0 or r>=n0 or used[int(r)]:return -1
    used[int(r)]=true;rank[i]=r
  var adj:array[10,array[10,bool]]
  for e in 0..<m:
    let u0=input[4+n+2*e];let v0=input[5+n+2*e]
    if u0<0 or u0>=n0 or v0<0 or v0>=n0 or u0==v0:return -1
    let u=int(u0);let v=int(v0);if adj[u][v]:return -1;adj[u][v]=true
  var dist:array[10,int64];for i in 0..<n:dist[i] = -1
  var queue:array[10,int];var head=0;var tail=0;dist[source]=0;queue[tail]=source;inc tail
  while head<tail:
    let u=queue[head];inc head
    for v in 0..<n:
      if adj[u][v] and dist[v]<0:dist[v]=dist[u]+1;queue[tail]=v;inc tail
  var staged:array[21,int64];var count=0
  for d in 0..<n:
    for v in 0..<n:
      if dist[v]!=int64(d):continue
      var less=0
      for x in 0..<n:
        if dist[x]>=0 and (dist[x]<dist[v] or (dist[x]==dist[v] and x<=v)) and rank[x]<rank[v]:inc less
      if less<k:staged[1+2*count]=int64(v);staged[2+2*count]=dist[v];inc count
  staged[0]=int64(count);let words=1+2*count;let bytes=8*words
  if output==nil or capacity<csize_t(bytes):return -2
  for i in 0..<words:putI64(output,8*i,staged[i])
  int64(bytes)
