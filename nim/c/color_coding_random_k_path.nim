const MaxN=12;const MaxM=66;const MaxK=6;const MaxTrials=8;const MaxInput=232;const MaxOutput=64
proc putI64(output:ptr UncheckedArray[uint8],offset:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[offset+b]=uint8((bits shr (8*b)) and 255)
proc pathLess(a,b:array[MaxK,int],length:int):bool=
  for i in 0..<length:
    if a[i]!=b[i]:return a[i]<b[i]
  false
proc color_coding_random_k_path*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"color_coding_random_k_path".}=
  if input==nil or length<4 or length>MaxInput:return -1
  if input[0]<1 or input[0]>int64(MaxN) or input[1]<0 or input[1]>int64(MaxM) or input[2]<1 or input[2]>int64(MaxK) or input[2]>input[0] or input[3]<1 or input[3]>int64(MaxTrials):return -1
  let n=int(input[0]);let m=int(input[1]);let k=int(input[2]);let trials=int(input[3]);let edgeStart=4;let colorStart=edgeStart+2*m
  if int(length)!=colorStart+trials*n:return -1
  var adj:array[MaxN,uint16]
  for e in 0..<m:
    let av=input[edgeStart+2*e];let bv=input[edgeStart+2*e+1]
    if av<0 or bv<0 or av>=int64(n) or bv>=int64(n) or av==bv:return -1
    let a=int(av);let b=int(bv);if (adj[a] and uint16(1 shl b))!=0:return -1
    adj[a]=adj[a] or uint16(1 shl b);adj[b]=adj[b] or uint16(1 shl a)
  for t in 0..<trials:
    for v in 0..<n:
      let c=input[colorStart+t*n+v];if c<0 or c>=int64(k):return -1
  let full=(1 shl k)-1
  for trial in 0..<trials:
    var colors:array[MaxN,int]
    for v in 0..<n:colors[v]=int(input[colorStart+trial*n+v])
    var reachable:array[1 shl MaxK,array[MaxN,bool]]
    var paths:array[1 shl MaxK,array[MaxN,array[MaxK,int]]]
    for mask in 0..full:
      for v in 0..<n:
        for j in 0..<k:paths[mask][v][j] = -1
    for v in 0..<n:
      let mask=1 shl colors[v];reachable[mask][v]=true;paths[mask][v][0]=v
    for mask in 1..full:
      var pathLen=0;var x=mask
      while x!=0:x=x and (x-1);inc pathLen
      for v in 0..<n:
        if reachable[mask][v] and mask!=full:
          for u in 0..<n:
            let bit=1 shl colors[u]
            if (adj[v] and uint16(1 shl u))==0 or (mask and bit)!=0:continue
            let next=mask or bit
            var candidate:array[MaxK,int]
            for j in 0..<pathLen:candidate[j]=paths[mask][v][j]
            candidate[pathLen]=u
            if not reachable[next][u] or pathLess(candidate,paths[next][u],pathLen+1):
              reachable[next][u]=true
              for j in 0..pathLen:paths[next][u][j]=candidate[j]
    var best = -1
    for v in 0..<n:
      if reachable[full][v] and (best<0 or pathLess(paths[full][v],paths[full][best],k)):best=v
    if best>=0:
      let bytes=8*(k+2);if output==nil or int(capacity)<bytes:return -2
      var staged:array[MaxOutput,uint8];putI64(addr staged[0],0,1);putI64(addr staged[0],8,int64(trial+1))
      for j in 0..<k:putI64(addr staged[0],8*(j+2),int64(paths[full][best][j]))
      for i in 0..<bytes:output[i]=staged[i]
      return int64(bytes)
  if output==nil or capacity<16:return -2
  var staged:array[16,uint8];putI64(addr staged[0],0,0);putI64(addr staged[0],8,0)
  for i in 0..<16:output[i]=staged[i]
  16
