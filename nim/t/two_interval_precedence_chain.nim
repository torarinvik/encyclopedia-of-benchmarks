# Clean-room longest precedence chain of 2-intervals.
const MaxN=16
proc before(v:ptr UncheckedArray[int64],a,b:int):bool=
  for q in 0..<4:
    let x=v[1+4*a+q];let y=v[1+4*b+q]
    if x!=y:return x<y
  a<b
proc precedes(v:ptr UncheckedArray[int64],a,b:int):bool=
  v[1+4*a+1]<v[1+4*b] and v[1+4*a+3]<v[1+4*b+2]
proc lexless(a:array[MaxN,int],an:int,b:array[MaxN,int],bn:int):bool=
  for i in 0..<min(an,bn):if a[i]!=b[i]:return a[i]<b[i]
  an<bn
proc two_interval_precedence_chain*(v:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"two_interval_precedence_chain".}=
  if v.isNil or length<5 or length>65 or v[0]<1 or v[0]>MaxN:return -1
  let n=int(v[0]);if int(length)!=1+4*n:return -1
  for i in 0..<n:
    let p=1+4*i
    for q in 0..<4:if v[p+q]<0 or v[p+q]>63:return -1
    if v[p]>=v[p+1] or v[p+2]>=v[p+3] or v[p+1]>=v[p+2]:return -1
  var order:array[MaxN,int]
  for i in 0..<n:order[i]=i
  for i in 1..<n:
    let value=order[i];var j=i
    while j>0 and before(v,value,order[j-1]):order[j]=order[j-1];dec j
    order[j]=value
  var paths:array[MaxN,array[MaxN,int]];var lens:array[MaxN,int]
  for i in 0..<n:
    paths[i][0]=order[i];lens[i]=1
    for j in 0..<i:
      if precedes(v,order[j],order[i]):
        var candidate=paths[j];candidate[lens[j]]=order[i];let m=lens[j]+1
        if m>lens[i] or (m==lens[i] and lexless(candidate,m,paths[i],lens[i])):paths[i]=candidate;lens[i]=m
  var best=0
  for i in 1..<n:if lens[i]>lens[best] or (lens[i]==lens[best] and lexless(paths[i],lens[i],paths[best],lens[best])):best=i
  var fields:array[17,int64];fields[0]=int64(lens[best]);for i in 0..<lens[best]:fields[i+1]=int64(paths[best][i])
  let bytes=8*(lens[best]+1);if out.isNil or capacity<csize_t(bytes):return -2
  for i in 0..<lens[best]+1:
    let bits=cast[uint64](fields[i])
    for b in 0..<8:out[8*i+b]=uint8((bits shr (8*b)) and 255)
  int64(bytes)
