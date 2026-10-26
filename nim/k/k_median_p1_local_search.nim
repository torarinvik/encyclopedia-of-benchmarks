const N=12
type Dist=array[144,int64]
type Centers=array[4,int]
proc put64(outp:ptr UncheckedArray[uint8],offset:int,x:int64)=
  let b=cast[uint64](x)
  for i in 0..<8:outp[offset+i]=uint8((b shr (8*i)) and 255)
proc objective(d:Dist,n:int,c:Centers,k:int):int64=
  for i in 0..<n:
    var best=high(int64)
    for j in 0..<k:best=min(best,d[i*N+c[j]])
    result+=best
proc sortCenters(c:var Centers,k:int)=
  for i in 1..<k:
    let x=c[i];var j=i
    while j>0 and c[j-1]>x:c[j]=c[j-1];dec j
    c[j]=x
proc less(a,b:Centers,k:int):bool=
  for i in 0..<k:
    if a[i]!=b[i]:return a[i]<b[i]
  false
proc k_median_p1_local_search*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"k_median_p1_local_search".}=
  if input==nil or length<2 or length>150:return -1
  let n0=input[0];let k0=input[1]
  if n0<2 or n0>12 or k0<1 or k0>4 or k0>n0 or int64(length)!=2+n0*n0+k0:return -1
  let n=int(n0);let k=int(k0);var d:Dist;var p=2
  for i in 0..<n:
    for j in 0..<n:
      let x=input[p];inc p
      if x<0 or x>1000:return -1
      d[i*N+j]=x
  for i in 0..<n:
    for j in 0..<n:
      if d[i*N+j]!=(if i==j:0'i64 else:d[i*N+j]) or d[i*N+j]!=d[j*N+i] or (i!=j and d[i*N+j]==0):return -1
      for h in 0..<n:
        if d[i*N+j]>d[i*N+h]+d[h*N+j]:return -1
  var selected:array[N,bool];var centers:Centers
  for j in 0..<k:
    let x=input[p];inc p
    if x<0 or x>=n0 or selected[int(x)]:return -1
    centers[j]=int(x);selected[int(x)]=true
  sortCenters(centers,k);var current=objective(d,n,centers,k)
  while true:
    var best=current;var bestc=centers;var have=false
    for leave in 0..<k:
      for enter in 0..<n:
        if selected[enter]:continue
        var cand=centers;cand[leave]=enter;sortCenters(cand,k)
        let value=objective(d,n,cand,k)
        if value<current and (value<best or (value==best and (not have or less(cand,bestc,k)))):
          best=value;bestc=cand;have=true
    if not have:break
    for i in 0..<k:selected[centers[i]]=false
    centers=bestc
    for i in 0..<k:selected[centers[i]]=true
    current=best
  let bytes=8*(2+k)
  if output==nil or capacity<csize_t(bytes):return -2
  put64(output,0,current);put64(output,8,int64(k))
  for i in 0..<k:put64(output,16+8*i,int64(centers[i]))
  int64(bytes)
