const MaxN=6
const MaxFields=7
const MaxInput=17
proc put(outp:ptr UncheckedArray[uint8],at:int,value:int64)=
  let bits=cast[uint64](value)
  for i in 0..<8:outp[at+i]=uint8((bits shr (8*i)) and 255)
proc wire_sizing*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"wire_sizing".}=
  if input.isNil or length<7 or length>csize_t(MaxInput):return -1
  let n64=input[0];if n64<1 or n64>MaxN:return -1
  let n=int(n64);let l=input[1];let rd=input[2];let cl=input[3];let r0=input[4]
  if l<1 or l>1000 or rd<1 or rd>1000 or cl<1 or cl>1000 or r0<1 or r0>1000 or int(length)!=5+2*n:return -1
  var h:array[MaxN,int64];var c:array[MaxN,int64]
  for i in 0..<n:
    h[i]=input[5+i];c[i]=input[5+n+i]
    if h[i]<1 or h[i]>32 or c[i]<1 or c[i]>1000 or (i>0 and h[i]>=h[i-1]) or (i>0 and c[i]>=c[i-1]):return -1
  var phi:array[MaxN,array[MaxN,float64]];var rho:array[MaxN,float64]
  for i in 0..<n:
    rho[i]=float64(rd)*float64(c[i])+float64(cl)*float64(r0)/float64(h[i])
    for j in 0..<n:
      let lo=min(i,j);let hi=max(i,j);phi[i][j]=float64(r0)*float64(c[hi])/float64(h[lo])
  var best=1.0e300;var bestL:array[MaxN,float64];var found=false
  for mask in 1..<(1 shl n):
    var ids:array[MaxN,int];var k=0
    for i in 0..<n:if (mask and (1 shl i))!=0:ids[k]=i;inc k
    var a:array[MaxN+1,array[MaxN+2,float64]]
    for r in 0..<k:
      for q in 0..<k:a[r][q]=phi[ids[r]][ids[q]]
      a[r][k]=1.0;a[r][k+1]= -rho[ids[r]]
    for q in 0..<k:a[k][q]=1.0
    a[k][k+1]=float64(l)
    var ok=true
    for col in 0..k:
      var pivot=col
      for r in col+1..k:if abs(a[r][col])>abs(a[pivot][col]):pivot=r
      if abs(a[pivot][col])<1.0e-12:ok=false;break
      if pivot!=col:swap(a[pivot],a[col])
      let divisor=a[col][col]
      for q in col..k+1:a[col][q]/=divisor
      for r in 0..k:
        if r!=col:
          let factor=a[r][col]
          for q in col..k+1:a[r][q]-=factor*a[col][q]
    if not ok:continue
    var x:array[MaxN,float64];for r in 0..<k:x[ids[r]]=a[r][k+1]
    let lambda=a[k][k+1];var total=0.0
    for i in 0..<n:
      if x[i]< -1.0e-8:ok=false
      total+=x[i];var gradient=rho[i]+lambda
      for j in 0..<n:gradient+=phi[i][j]*x[j]
      if (mask and (1 shl i))==0 and gradient< -1.0e-7:ok=false
    if abs(total-float64(l))>1.0e-7:ok=false
    if not ok:continue
    var objective=float64(rd*cl)
    for i in 0..<n:
      objective+=rho[i]*x[i]
      for j in 0..<n:objective+=0.5*x[i]*phi[i][j]*x[j]
    if not found or objective<best-1.0e-7:found=true;best=objective;bestL=x
  if not found:return -1
  var fields:array[MaxFields,int64];fields[0]=int64(best*1.0e6+0.5)
  for i in 0..<n:fields[i+1]=int64(max(0.0,bestL[i])*1.0e6+0.5)
  let bytes=8*(n+1)
  if output.isNil or capacity<csize_t(bytes):return -2
  var staged:array[8*MaxFields,uint8]
  for i in 0..<n+1:put(addr staged[0],8*i,fields[i])
  for i in 0..<bytes:output[i]=staged[i]
  int64(bytes)
