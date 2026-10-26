const
  MaxN = 12
  MaxM = 66
  MaxQ = 32
  MaxInput = 266
  Inf = high(int64) div 4

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset + b] = uint8((bits shr (8 * b)) and 255)

proc thorup_zwick_distance_oracle*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 =
  if input.isNil or length < 4 or length > MaxInput: return -1
  let n64=input[0];let m64=input[1];let mask=input[2]
  if n64<1 or n64>MaxN or m64<0 or m64>MaxM or mask<=0:return -1
  let n=int(n64);let m=int(m64)
  if (cast[uint64](mask) shr n)!=0:return -1
  let qAt=3+3*m
  if qAt>=int(length) or input[qAt]<0 or input[qAt]>MaxQ:return -1
  let q=int(input[qAt])
  if int(length)!=qAt+1+2*q:return -1
  var d:array[MaxN,array[MaxN,int64]]
  for i in 0..<n:
    for j in 0..<n:d[i][j]=if i==j:0 else:Inf
  for e in 0..<m:
    let u=input[3+3*e];let v=input[4+3*e];let w=input[5+3*e]
    if u<0 or v<=u or v>=n64 or w<1 or w>1000:return -1
    if d[int(u)][int(v)]!=Inf:return -1
    d[int(u)][int(v)]=w;d[int(v)][int(u)]=w
  for k in 0..<n:
    for i in 0..<n:
      for j in 0..<n:
        if d[i][k]!=Inf and d[k][j]!=Inf and d[i][k]+d[k][j]<d[i][j]:d[i][j]=d[i][k]+d[k][j]
  for i in 0..<n:
    for j in 0..<n:if d[i][j]==Inf:return -1
  var nearest:array[MaxN,int]
  var nearD:array[MaxN,int64]
  for v in 0..<n:
    nearest[v] = -1;nearD[v]=Inf
    for a in 0..<n:
      if ((cast[uint64](mask) shr a) and 1'u64)!=0 and (d[v][a]<nearD[v] or (d[v][a]==nearD[v] and (nearest[v]<0 or a<nearest[v]))):
        nearest[v]=a;nearD[v]=d[v][a]
  var bunch:array[MaxN,array[MaxN,bool]]
  for u in 0..<n:
    for x in 0..<n:bunch[u][x]=(((cast[uint64](mask) shr x) and 1'u64)!=0) or d[u][x]<nearD[u]
  var staged:array[MaxQ+1,int64]
  staged[0]=int64(q)
  for z in 0..<q:
    let a=input[qAt+1+2*z];let b=input[qAt+2+2*z]
    if a<0 or a>=n64 or b<0 or b>=n64:return -1
    var u=int(a);var v=int(b);var found=false
    for level in 0..<2:
      let pivot=if level==0:v else:nearest[v]
      if bunch[u][pivot]:staged[z+1]=d[u][pivot]+d[v][pivot];found=true;break
      swap(u,v)
    if not found:return -1
  let bytes=8*(q+1)
  if output.isNil or capacity<csize_t(bytes):return -2
  for i in 0..<q+1:putI64(output,8*i,staged[i])
  int64(bytes)
