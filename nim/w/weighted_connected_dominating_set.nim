# Clean-room exact bounded minimum weighted connected dominating set.
const MaxN=16
proc put(out:ptr UncheckedArray[uint8],at:int,x:int64)=
  let bits=cast[uint64](x)
  for i in 0..<8:out[at+i]=uint8((bits shr (8*i)) and 255)
proc weighted_connected_dominating_set*(v:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"weighted_connected_dominating_set".}=
  if v.isNil or length<3 or length>33 or v[0]<1 or v[0]>MaxN:return -1
  let n=int(v[0]);if int(length)!=1+2*n:return -1
  let all=(1'u64 shl n)-1
  var adj:array[MaxN,uint64]
  for i in 0..<n:
    let mask=v[1+i];let weight=v[1+n+i]
    if mask<0 or uint64(mask)>all or (uint64(mask) and (1'u64 shl i))!=0 or weight<1 or weight>1000:return -1
    adj[i]=uint64(mask)
  for i in 0..<n:for j in 0..<n:if ((adj[i] shr j) and 1)!=((adj[j] shr i) and 1):return -1
  var bestCost:int64 = -1;var bestMask=0'u64
  var mask=1'u64
  while mask<=all:
    var dominated=mask;var cost=0'i64
    for i in 0..<n:
      if ((mask shr i) and 1)!=0:
        dominated=dominated or adj[i]
        cost+=v[1+n+i]
    if dominated==all:
      var seen=mask and (not mask+1'u64)
      while true:
        let old=seen
        for i in 0..<n:if ((seen shr i) and 1)!=0:seen=seen or (adj[i] and mask)
        if seen==old:break
      if seen==mask and (bestCost<0 or cost<bestCost or (cost==bestCost and mask<bestMask)):bestCost=cost;bestMask=mask
    inc mask
  if out.isNil or capacity<16:return -2
  put(out,0,bestCost);put(out,8,int64(bestMask));16
