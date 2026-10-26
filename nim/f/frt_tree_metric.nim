proc within(d, beta: int64, level: int): bool =
  if level >= 0: d * 1024 <= beta * (1'i64 shl level)
  else: d * 1024 * (1'i64 shl (-level)) <= beta

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset+b] = uint8((bits shr (8*b)) and 255)

proc frt_tree_metric*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "frt_tree_metric".} =
  if input.isNil or length < 8 or length > 74: return -1
  let n0=input[0];let beta=input[1]
  if n0<2 or n0>8 or beta<1024 or beta>2047:return -1
  let n=int(n0)
  if int(length)!=2+n+n*n:return -1
  var perm:array[8,int]
  var seen:array[8,bool]
  for i in 0..<n:
    let p=input[2+i]
    if p<0 or p>=n0 or seen[int(p)]:return -1
    seen[int(p)]=true;perm[i]=int(p)
  var d:array[8,array[8,int64]]
  var maxd=0'i64;let base=2+n
  for i in 0..<n:
    for j in 0..<n:
      let x=input[base+i*n+j]
      if x<0 or x>255 or (i==j and x!=0) or (i!=j and x==0):return -1
      d[i][j]=x
      if x>maxd:maxd=x
  for i in 0..<n:
    for j in 0..<n:
      if d[i][j]!=d[j][i]:return -1
      for k in 0..<n:
        if d[i][j]>d[i][k]+d[k][j]:return -1
  var high=0
  while (1'i64 shl high)<maxd:inc high
  var staged:array[64,int64]
  var clusters:array[256,uint16]
  var next:array[256,uint16]
  var count=1;clusters[0]=uint16((1 shl n)-1)
  for level in countdown(high,-10):
    var nextCount=0
    let treeDistance=1'i64 shl (level+13)
    for ci in 0..<count:
      var remaining=clusters[ci];var done=0'u16
      while remaining!=0:
        var center=n
        for p in 0..<n:
          if (remaining and (1'u16 shl perm[p]))!=0:center=perm[p];break
        if center==n:return -1
        var child=0'u16
        for v in 0..<n:
          if (remaining and (1'u16 shl v))!=0 and within(d[center][v],beta,level):child=child or (1'u16 shl v)
        if child==0:child=1'u16 shl center
        for u in 0..<n:
          if (done and (1'u16 shl u))!=0:
            for v in 0..<n:
              if (child and (1'u16 shl v))!=0:
                staged[u*n+v]=treeDistance;staged[v*n+u]=treeDistance
        done=done or child;remaining=remaining and not child
        next[nextCount]=child;inc nextCount
    for i in 0..<nextCount:clusters[i]=next[i]
    count=nextCount
  let bytes=8*n*n
  if output.isNil or int(capacity)<bytes:return -2
  for i in 0..<n*n:putI64(output,i*8,staged[i])
  int64(bytes)
