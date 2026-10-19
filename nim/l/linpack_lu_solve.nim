import std/math
const InvalidResult = -1e300
proc dgefa(a: var array[16,float64],n:int,ipvt: var array[4,int]):int=
  var info=0
  let nm1=n-1
  if nm1>=0:
    for k in 0..<nm1:
      let kp1=k+1
      var l=k
      var maximum=abs(a[n*k+k])
      for i in 1..<(n-k):
        let candidate=abs(a[n*k+k+i])
        if candidate>maximum:l=k+i;maximum=candidate
      ipvt[k]=l
      if a[n*k+l]!=0.0:
        if l!=k:swap(a[n*k+l],a[n*k+k])
        let factor= -1.0/a[n*k+k]
        for i in 0..<(n-(k+1)):a[n*k+k+1+i]=factor*a[n*k+k+1+i]
        for j in kp1..<n:
          var t=a[n*j+l]
          if l!=k: a[n*j+l]=a[n*j+k];a[n*j+k]=t
          if t!=0.0:
            for i in 0..<(n-(k+1)):a[n*j+k+1+i]=a[n*j+k+1+i]+t*a[n*k+k+1+i]
      else:info=k
  ipvt[n-1]=n-1
  if a[n*(n-1)+(n-1)]==0.0:info=n-1
  info
proc dgesl(a:array[16,float64],n:int,ipvt:array[4,int],b:var array[4,float64])=
  let nm1=n-1
  if nm1>=1:
    for k in 0..<nm1:
      let l=ipvt[k]
      let t=b[l]
      if l!=k:swap(b[l],b[k])
      if t!=0.0:
        for i in 0..<(n-(k+1)):b[k+1+i]=b[k+1+i]+t*a[n*k+k+1+i]
  for kb in 0..<n:
    let k=n-(kb+1)
    b[k]=b[k]/a[n*k+k]
    let t= -b[k]
    if t!=0.0:
      for i in 0..<k:b[i]=b[i]+t*a[n*k+i]
proc linpack_lu_solve*(input:ptr UncheckedArray[int64],length:csize_t):float64 {.cdecl,exportc:"linpack_lu_solve".}=
  if input==nil or length<1 or length>22:return InvalidResult
  let rawN=input[0]
  if rawN<2 or rawN>4:return InvalidResult
  let n=int(rawN)
  if length!=csize_t(1+n*n+n):return InvalidResult
  var a:array[16,float64]
  var b:array[4,float64]
  var ipvt:array[4,int]
  for i in 0..<n*n:
    let value=input[1+i]
    if value< -8 or value>8:return InvalidResult
    a[i]=float64(value)
  for i in 0..<n:
    let value=input[1+n*n+i]
    if value< -32 or value>32:return InvalidResult
    b[i]=float64(value)
  if dgefa(a,n,ipvt)!=0:return InvalidResult
  dgesl(a,n,ipvt,b)
  var result=0.0
  for i in 0..<n:result+=float64(i+1)*b[i]
  if classify(result) in {fcNan,fcInf,fcNegInf}:return InvalidResult
  result
