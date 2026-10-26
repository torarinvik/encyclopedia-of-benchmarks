## Exact chromatic number through independent-set inclusion-exclusion.
proc exact_graph_coloring_inclusion_exclusion*(x: ptr UncheckedArray[int64], length:csize_t,
    output:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"exact_graph_coloring_inclusion_exclusion".}=
  if x==nil:return -2
  if length<2 or length>44:return -1
  let nv=x[0];let mv=x[1]
  if nv<1 or nv>7 or mv<0 or mv>21 or int(length)!=2+2*int(mv):return -1
  let n=int(nv);let m=int(mv);var adj:array[7,array[7,bool]]
  for e in 0..<m:
    let u=x[2+2*e];let v=x[3+2*e]
    if u<0 or v<0 or u>=nv or v>=nv or u==v:return -1
    let a=int(u);let b=int(v);if adj[a][b]:return -1;adj[a][b]=true;adj[b][a]=true
  let lim=1 shl n;var cnt:array[128,int64];cnt[0]=1
  for mask in 1..<lim:
    let bit=mask and -mask;var v=0
    while (1 shl v)!=bit:inc v
    let rest=mask xor bit;var allowed=rest
    for u in 0..<n:if adj[v][u]:allowed=allowed and not (1 shl u)
    cnt[mask]=cnt[rest]+cnt[allowed]
  var chi=int64(n)
  for k in 1..n:
    var sum:int64=0
    for mask in 0..<lim:
      var term:int64=1
      let base=cnt[mask]-1
      for q in 0..<k:term*=base
      var pc=0;var bits=mask
      while bits!=0:bits=bits and (bits-1);inc pc
      if (n-pc) mod 2==0:sum+=term else:sum-=term
    if sum>0:chi=int64(k);break
  if cap<8 or output==nil:return -2
  let raw=cast[uint64](chi)
  for i in 0..<8:output[i]=uint8((raw shr (8*i)) and 255)
  return 8
