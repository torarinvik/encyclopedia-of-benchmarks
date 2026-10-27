const MaxTotal=8
const MaxM=7
const MaxInput=75
proc put(o:ptr UncheckedArray[uint8],at:int,x:int64)=
  let b=cast[uint64](x)
  for i in 0..<8:o[at+i]=uint8((b shr (8*i)) and 255)
proc lexLess(a,b:uint32,m:int):bool=
  var i=0;var j=0
  while true:
    while i<m and (a and (1'u32 shl i))==0:inc i
    while j<m and (b and (1'u32 shl j))==0:inc j
    if i==m or j==m:return i==m and j!=m
    if i!=j:return i<j
    inc i;inc j
proc objective(n,m:int,d:array[MaxTotal,array[MaxTotal,int64]],fee:array[MaxM,int64],mask:uint32):int64=
  var x=0'i64
  for j in 0..<m:if (mask and (1'u32 shl j))!=0:x+=fee[j]
  for u in 0..<n:
    var best=high(int64)
    for j in 0..<m:if (mask and (1'u32 shl j))!=0:best=min(best,d[u][n+j])
    x+=best
  x
proc consider(c:uint32,n,m:int,d:array[MaxTotal,array[MaxTotal,int64]],fee:array[MaxM,int64],best:var uint32,bestCost:var int64)=
  let v=objective(n,m,d,fee,c)
  if v<bestCost or (v==bestCost and lexLess(c,best,m)):best=c;bestCost=v
proc facility_location_add_delete_swap*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"facility_location_add_delete_swap".}=
  if input.isNil or length<4 or length>csize_t(MaxInput):return -1
  let n0=input[0];let m0=input[1]
  if n0<1 or m0<1 or n0+m0>8 or n0>7 or m0>7:return -1
  let n=int(n0);let m=int(m0);let q=n+m
  if int(length)!=2+q*q+m+1:return -1
  var d:array[MaxTotal,array[MaxTotal,int64]];var fee:array[MaxM,int64];var p=2
  for i in 0..<q:for j in 0..<q:
    let v=input[p];inc p
    if v<0 or v>1000:return -1
    d[i][j]=v
  for i in 0..<q:
    if d[i][i]!=0:return -1
    for j in 0..<q:
      if i!=j and d[i][j]<=0:return -1
      if d[i][j]!=d[j][i]:return -1
      for k in 0..<q:if d[i][j]>d[i][k]+d[k][j]:return -1
  for j in 0..<m:
    fee[j]=input[p];inc p
    if fee[j]<0 or fee[j]>1000:return -1
  let raw=input[p]
  if raw<=0 or uint64(raw)>=(1'u64 shl m):return -1
  var current=uint32(raw)
  var currentCost=objective(n,m,d,fee,current)
  for pass in 0..<(1 shl m):
    var best=current;var bestCost=currentCost
    for j in 0..<m:
      let bit=1'u32 shl j
      if (current and bit)==0:consider(current or bit,n,m,d,fee,best,bestCost)
      elif (current and not bit)!=0:
        consider(current and not bit,n,m,d,fee,best,bestCost)
        for k in 0..<m:
          let other=1'u32 shl k
          if (current and other)==0:consider((current and not bit) or other,n,m,d,fee,best,bestCost)
    if bestCost*10>=currentCost*9:break
    current=best;currentCost=bestCost
  var count=0
  for j in 0..<m:if (current and (1'u32 shl j))!=0:inc count
  let outBytes=8*(2+n+count)
  if output.isNil or capacity<csize_t(outBytes):return -2
  put(output,0,currentCost);put(output,8,int64(count));var at=16
  for j in 0..<m:if (current and (1'u32 shl j))!=0:put(output,at,int64(j));at+=8
  for u in 0..<n:
    var b=0;var dist=high(int64)
    for j in 0..<m:if (current and (1'u32 shl j))!=0 and d[u][n+j]<dist:dist=d[u][n+j];b=j
    put(output,at,int64(b));at+=8
  int64(at)
