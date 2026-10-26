proc putI64(outp: ptr UncheckedArray[uint8], x: int64) =
  let b = cast[uint64](x)
  for i in 0 ..< 8: outp[i] = uint8((b shr (8*i)) and 255)

proc domination_local_reduction*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "domination_local_reduction".} =
  if input.isNil or length < 3 or length > 135: return -1
  let n0=input[0]; let m0=input[1]; let p0=input[2]
  if n0<1 or n0>12 or m0<0 or m0>66 or p0<0 or p0>=n0 or int(length)!=3+2*int(m0): return -1
  let n=int(n0);let m=int(m0);let p=int(p0)
  var a: array[12,array[12,bool]]
  for e in 0 ..< m:
    let u0=input[3+2*e];let v0=input[4+2*e]
    if u0<0 or v0<=u0 or v0>=n0:return -1
    let u=int(u0);let v=int(v0);if a[u][v]:return -1;a[u][v]=true;a[v][u]=true
  var closed,exits,guards,prisoners: array[12,bool]
  closed[p]=true
  for u in 0 ..< n: if a[p][u]: closed[u]=true
  for u in 0 ..< n:
    if a[p][u]:
      for x in 0 ..< n:
        if a[u][x] and not closed[x]: exits[u]=true;break
  for u in 0 ..< n:
    if a[p][u] and not exits[u]:
      for x in 0 ..< n:
        if exits[x] and a[u][x]: guards[u]=true;break
  var np=0
  for u in 0 ..< n: if a[p][u] and not exits[u] and not guards[u]: prisoners[u]=true;inc np
  if np==0:return -1
  var ids: array[12,int];var remap: array[12,int];for u in 0 ..< n:remap[u]= -1
  var kept=0
  for u in 0 ..< n: if not guards[u] and not prisoners[u]:ids[kept]=u;remap[u]=kept;inc kept
  let k=kept+1;let leaf=k-1
  var words: array[25,int64];words[0]=int64(k)
  for i in 0 ..< kept:words[1+i]=int64(ids[i])
  words[1+kept]= -1
  for i in 0 ..< kept:
    for j in 0 ..< kept:if a[ids[i]][ids[j]]:words[1+k+i]=words[1+k+i] or (1'i64 shl j)
  words[1+k+remap[p]]=words[1+k+remap[p]] or (1'i64 shl leaf)
  words[1+k+leaf]=1'i64 shl remap[p]
  let count=1+2*k;let bytes=count*8
  if output.isNil or int(capacity)<bytes:return -2
  for i in 0 ..< count:
    let b=cast[uint64](words[i])
    for j in 0 ..< 8:output[8*i+j]=uint8((b shr (8*j)) and 255)
  int64(bytes)
