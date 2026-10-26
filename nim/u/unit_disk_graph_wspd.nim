const MaxN=8
const MaxPairs=28
const MaxInput=18
const Inf=int64.high div 4
type Context=object
  n,c,count:int
  distance:array[MaxN,array[MaxN,int64]]
  pairs:array[MaxPairs,tuple[a,b:uint64]]
proc bitCount(mask0:uint64):int=
  var mask=mask0
  while mask!=0:result+=int(mask and 1);mask=mask shr 1
proc split(mask:uint64):tuple[a,b:uint64]=
  let half=bitCount(mask) div 2
  var seen=0
  for i in 0..<MaxN:
    if ((mask shr i) and 1'u64)!=0:
      if seen<half:result.a=result.a or (1'u64 shl i)
      else:result.b=result.b or (1'u64 shl i)
      inc seen
proc diameter(x:Context,mask:uint64):int64=
  for i in 0..<x.n:
    if ((mask shr i) and 1'u64)!=0:
      for j in i+1..<x.n:
        if ((mask shr j) and 1'u64)!=0:result=max(result,x.distance[i][j])
proc setDistance(x:Context,a,b:uint64):int64=
  result=Inf
  for i in 0..<x.n:
    if ((a shr i) and 1'u64)!=0:
      for j in 0..<x.n:
        if ((b shr j) and 1'u64)!=0:result=min(result,x.distance[i][j])
proc cross(x:var Context,a,b:uint64)=
  let da=diameter(x,a);let db=diameter(x,b)
  if setDistance(x,a,b)>=int64(x.c)*max(da,db):
    if x.count<MaxPairs:x.pairs[x.count]=(a,b);inc x.count
    return
  if bitCount(a)>=bitCount(b) and bitCount(a)>1:
    let halves=split(a);cross(x,halves.a,b);cross(x,halves.b,b)
  else:
    let halves=split(b);cross(x,a,halves.a);cross(x,a,halves.b)
proc visit(x:var Context,mask:uint64)=
  if bitCount(mask)<2:return
  let halves=split(mask);visit(x,halves.a);visit(x,halves.b);cross(x,halves.a,halves.b)
proc put(outp:ptr UncheckedArray[uint8],at:int,value:int64)=
  let bits=cast[uint64](value)
  for i in 0..<8:outp[at+i]=uint8((bits shr (8*i)) and 255)
proc unit_disk_graph_wspd*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"unit_disk_graph_wspd".}=
  if input.isNil or length<4 or length>csize_t(MaxInput):return -1
  let n64=input[0];let c64=input[1]
  if n64<1 or n64>MaxN or c64<1 or c64>8 or int(length)!=2+2*int(n64):return -1
  let n=int(n64);var px:array[MaxN,int64];var py:array[MaxN,int64]
  for i in 0..<n:
    px[i]=input[2+2*i];py[i]=input[3+2*i]
    if px[i]< -8 or px[i]>8 or py[i]< -8 or py[i]>8:return -1
    for j in 0..<i:if px[i]==px[j] and py[i]==py[j]:return -1
  var x:Context;x.n=n;x.c=int(c64)
  for i in 0..<n:
    for j in 0..<n:x.distance[i][j]=if i==j:0 else:Inf
  for i in 0..<n:
    for j in i+1..<n:
      let dx=px[i]-px[j];let dy=py[i]-py[j]
      if dx*dx+dy*dy<=1:x.distance[i][j]=1;x.distance[j][i]=1
  for k in 0..<n:
    for i in 0..<n:
      for j in 0..<n:x.distance[i][j]=min(x.distance[i][j],x.distance[i][k]+x.distance[k][j])
  for i in 0..<n:
    for j in 0..<n:if x.distance[i][j]>=Inf div 2:return -1
  visit(x,(1'u64 shl n)-1)
  let bytes=8+16*x.count
  if output.isNil or capacity<csize_t(bytes):return -2
  var staged:array[456,uint8]
  put(addr staged[0],0,int64(x.count))
  for i in 0..<x.count:put(addr staged[0],8+16*i,int64(x.pairs[i].a));put(addr staged[0],16+16*i,int64(x.pairs[i].b))
  for i in 0..<bytes:output[i]=staged[i]
  int64(bytes)
