const MaxWords=32
const MaxWordLen=8
const MaxInput=307
proc eq(v:ptr UncheckedArray[int64],s,n,t,m:int):bool =
  if n!=m:return false
  for i in 0..<n:
    if v[s+i]!=v[t+i]:return false
  true
proc shortest_word_distance*(v:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"shortest_word_distance".}=
  if v.isNil or length<1 or length>csize_t(MaxInput+1):return -1
  if v[0]<2 or v[0]>MaxWords:return -1
  let n=int(v[0]);var starts,sizes:array[MaxWords,int];var p=1
  for i in 0..<n:
    if p>=int(length):return -1
    let z=v[p];inc p
    if z<1 or z>MaxWordLen or p+int(z)>int(length):return -1
    starts[i]=p;sizes[i]=int(z)
    for j in 0..<int(z):
      if not ((v[p+j]>=65 and v[p+j]<=90) or (v[p+j]>=97 and v[p+j]<=122)):return -1
    p+=int(z)
  var ts,tn:array[2,int]
  for t in 0..1:
    if p>=int(length):return -1
    let z=v[p];inc p
    if z<1 or z>MaxWordLen or p+int(z)>int(length):return -1
    ts[t]=p;tn[t]=int(z)
    for j in 0..<int(z):
      if not ((v[p+j]>=65 and v[p+j]<=90) or (v[p+j]>=97 and v[p+j]<=122)):return -1
    p+=int(z)
  if p!=int(length) or eq(v,ts[0],tn[0],ts[1],tn[1]):return -1
  var h0=false;var h1=false;var best=n
  for i in 0..<n:
    let a=eq(v,starts[i],sizes[i],ts[0],tn[0]);let b=eq(v,starts[i],sizes[i],ts[1],tn[1]);h0=h0 or a;h1=h1 or b
    for j in 0..<n:
      let c=eq(v,starts[j],sizes[j],ts[0],tn[0]);let d=eq(v,starts[j],sizes[j],ts[1],tn[1])
      if (a and d) or (b and c):best=min(best,abs(i-j))
  if not h0 or not h1:return -1
  int64(best)
