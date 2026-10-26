## Bounded exact closest-string center by lexicographic exhaustive search.
proc closest_string_center*(x:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"closest_string_center".}=
  if x==nil:return -2
  if length<3 or length>51:return -1
  let nv=x[0];let mv=x[1];let qv=x[2]
  if nv<1 or nv>6 or mv<1 or mv>8 or (qv!=2 and qv!=3) or int(length)!=3+int(nv*mv):return -1
  let n=int(nv);let m=int(mv);let q=int(qv)
  for i in 3..<int(length):if x[i]<0 or x[i]>=qv:return -1
  var total=1;for _ in 0..<m:total*=q
  var best=m+1;var bestc:array[8,int]
  for code in 0..<total:
    var v=code;var candidate:array[8,int]
    for p0 in 0..<m:
      let p=m-1-p0;candidate[p]=v mod q;v=v div q
    var radius=0
    for row in 0..<n:
      var d=0
      for col in 0..<m:if int64(candidate[col])!=x[3+row*m+col]:inc d
      if d>radius:radius=d
    if radius<best:best=radius;bestc=candidate
  let bytes=8*(m+1)
  if int(cap)<bytes or (out==nil and bytes>0):return -2
  let rb=uint64(best)
  for b in 0..<8:out[b]=uint8((rb shr (8*b)) and 255)
  for j in 0..<m:
    let z=uint64(bestc[j])
    for b in 0..<8:out[8*(j+1)+b]=uint8((z shr (8*b)) and 255)
  return int64(bytes)
