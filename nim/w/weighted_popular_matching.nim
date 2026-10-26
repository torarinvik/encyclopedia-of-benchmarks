# Clean-room exhaustive solver for bounded weighted popular matchings.
const MaxN=4;MaxFields=6
proc decode(code0:int,n,m:int,a:var array[MaxN,int]):bool=
  var code=code0;var used=0
  for i in 0..<n:
    let digit=code mod (m+1);code=code div (m+1);a[i]=digit-1
    if digit>0:
      let bit=1 shl (digit-1)
      if (used and bit)!=0:return false
      used=used or bit
  true
proc lexless(a,b:array[MaxN,int],n:int):bool=
  for i in 0..<n:if a[i]!=b[i]:return a[i]<b[i]
  false
proc put(out:ptr UncheckedArray[uint8],at:int,x:int64)=
  let bits=cast[uint64](x)
  for i in 0..<8:out[at+i]=uint8((bits shr (8*i)) and 255)
proc weighted_popular_matching*(v:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"weighted_popular_matching".}=
  if v.isNil or length<4 or length>22 or v[0]<1 or v[0]>MaxN or v[1]<1 or v[1]>MaxN:return -1
  let n=int(v[0]);let m=int(v[1]);if int(length)!=2+n+n*m:return -1
  for i in 0..<n:
    if v[2+i]<1 or v[2+i]>1000:return -1
    var seen=0
    for j in 0..<m:
      let rank=v[2+n+i*m+j]
      if rank<0 or rank>=int64(m) or (seen and (1 shl int(rank)))!=0:return -1
      seen=seen or (1 shl int(rank))
  var total=1
  for i in 0..<n:total*=m+1
  var bestCard = -1
  var best:array[MaxN,int];for i in 0..<MaxN:best[i] = -1
  for code in 0..<total:
    var candidate:array[MaxN,int]
    if not decode(code,n,m,candidate):continue
    var popular=true
    for otherCode in 0..<total:
      var other:array[MaxN,int]
      if not decode(otherCode,n,m,other):continue
      var score=0'i64
      for i in 0..<n:
        let rc=if candidate[i]<0:int64(m) else:v[2+n+i*m+candidate[i]]
        let ro=if other[i]<0:int64(m) else:v[2+n+i*m+other[i]]
        if ro<rc:score+=v[2+i]
        elif ro>rc:score-=v[2+i]
      if score>0:popular=false;break
    if popular:
      var card=0
      for i in 0..<n:if candidate[i]>=0:inc card
      if card>bestCard or (card==bestCard and lexless(candidate,best,n)):bestCard=card;best=candidate
  var fields:array[MaxFields,int64]
  fields[0]=if bestCard<0:0 else:1
  fields[1]=int64(max(bestCard,0))
  for i in 0..<n:fields[2+i]=if bestCard<0: -1 else:int64(best[i])
  if out.isNil or capacity<csize_t(8*(n+2)):return -2
  for i in 0..<n+2:put(out,8*i,fields[i])
  int64(8*(n+2))
