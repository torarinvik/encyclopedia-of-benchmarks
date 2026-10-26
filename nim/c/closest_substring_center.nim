## Bounded exact closest-substring center by lexicographic exhaustive search.
proc closest_substring_center*(x:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"closest_substring_center".}=
  if x==nil:return -2
  if length<4 or length>44:return -1
  let nv=x[0];let mv=x[1];let lv=x[2];let qv=x[3]
  if nv<1 or nv>4 or mv<1 or mv>10 or lv<1 or lv>8 or lv>mv or (qv!=2 and qv!=3) or int(length)!=4+int(nv*mv):return -1
  let n=int(nv);let m=int(mv);let l=int(lv);let q=int(qv)
  for i in 4..<int(length):if x[i]<0 or x[i]>=qv:return -1
  var total=1;for _ in 0..<l:total*=q
  var best=l+1;var bc:array[8,int]
  for code in 0..<total:
    var v=code;var cand:array[8,int]
    for p0 in 0..<l:let p=l-1-p0;cand[p]=v mod q;v=v div q
    var radius=0
    for row in 0..<n:
      var rb=l+1
      for st in 0..<(m-l+1):
        var d=0
        for j in 0..<l:if cand[j]!=int(x[4+row*m+st+j]):inc d
        if d<rb:rb=d
      if rb>radius:radius=rb
    if radius<best:best=radius;bc=cand
  let bytes=8*(l+1)
  if int(cap)<bytes or (out==nil and bytes>0):return -2
  let z=uint64(best);for b in 0..<8:out[b]=uint8((z shr (8*b)) and 255)
  for j in 0..<l:let value=uint64(bc[j]);for b in 0..<8:out[8*(j+1)+b]=uint8((value shr (8*b)) and 255)
  return int64(bytes)
