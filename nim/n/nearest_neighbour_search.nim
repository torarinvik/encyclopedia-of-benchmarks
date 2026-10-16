proc nodeBase(d,i:int): int = 2+d+i*(d+2)
proc validateTree(v: ptr UncheckedArray[int64], d,n,i:int, seen: var array[15,bool], reached: var int): bool =
  if i < 0: return true
  if i >= n or seen[i]: return false
  seen[i]=true; inc reached
  let b=nodeBase(d,i); let left=int(v[b+d]); let right=int(v[b+d+1])
  if left >= 0 and left == right: return false
  validateTree(v,d,n,left,seen,reached) and validateTree(v,d,n,right,seen,reached)
proc searchTree(v: ptr UncheckedArray[int64], d,i,depth:int,q: array[3,int64], best: var array[3,int64], bestDist: var int64, visited: var int64) =
  if i < 0: return
  inc visited
  let b=nodeBase(d,i); var dist:int64=0
  for k in 0..<d:
    let delta=q[k]-v[b+k]
    dist += delta*delta
  if dist < bestDist:
    bestDist=dist
    for k in 0..<d:
      best[k]=v[b+k]
  let axis=depth mod d; let left=int(v[b+d]); let right=int(v[b+d+1])
  let near=if q[axis] <= v[b+axis]: left else: right
  let far=if q[axis] <= v[b+axis]: right else: left
  searchTree(v,d,near,depth+1,q,best,bestDist,visited)
  let split=q[axis]-v[b+axis]
  if split*split < bestDist: searchTree(v,d,far,depth+1,q,best,bestDist,visited)
proc putI64(outp: ptr UncheckedArray[uint8], offset:int, x:int64) =
  let bits=cast[uint64](x)
  for k in 0..<8: outp[offset+k]=uint8((bits shr (8*k)) and 255)
proc nearest_neighbour_search*(v: ptr UncheckedArray[int64], n:csize_t, outp:ptr UncheckedArray[uint8], cap:csize_t):int64 {.cdecl,exportc:"nearest_neighbour_search".} =
  if v==nil or n<5:return -1
  let d0=v[0];let n0=v[1]
  if (d0!=2 and d0!=3) or n0<1 or n0>15:return -1
  let d=int(d0);let count=int(n0)
  if n!=csize_t(2+d+count*(d+2)):return -1
  var q:array[3,int64];var best:array[3,int64]
  for k in 0..<d:
    q[k]=v[2+k]
    if q[k] < -1000 or q[k] > 1000: return -1
  for i in 0..<count:
    let b=nodeBase(d,i)
    for k in 0..<d:
      if v[b+k] < -1000 or v[b+k] > 1000: return -1
    let l=v[b+d];let r=v[b+d+1]
    if l < -1 or l>=n0 or r < -1 or r>=n0 or (l>=0 and l==r):return -1
  var seen:array[15,bool];var reached=0
  if not validateTree(v,d,count,0,seen,reached) or reached!=count:return -1
  var bestDist=high(int64);var visited:int64=0
  searchTree(v,d,0,0,q,best,bestDist,visited)
  if outp==nil or cap<48:return -2
  let result=[d0,best[0],best[1],(if d==3:best[2] else:0'i64),bestDist,visited]
  for k in 0..<6:putI64(outp,k*8,result[k])
  48
