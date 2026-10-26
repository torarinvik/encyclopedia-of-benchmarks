# Clean-room Lexicographic Depth-First Search with 4-vertex certificates.
const MaxN=8;MaxFields=234
proc put(out:ptr UncheckedArray[uint8],at:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:out[at+b]=uint8((bits shr (8*b)) and 255)
proc ldfs_ordering_certificate*(v:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"ldfs_ordering_certificate".}=
  if v.isNil or length<3 or length>10:return -1
  if v[0]<1 or v[0]>MaxN:return -1
  let n=int(v[0]);if int(length)!=n+2 or v[1]<0 or v[1]>=int64(n):return -1
  let all=(1'u64 shl n)-1
  var adj:array[MaxN,uint64]
  for i in 0..<n:
    if v[2+i]<0 or uint64(v[2+i])>all or (uint64(v[2+i]) and (1'u64 shl i))!=0:return -1
    adj[i]=uint64(v[2+i])
  for i in 0..<n:
    for j in 0..<n:if ((adj[i] shr j) and 1)!=( (adj[j] shr i) and 1):return -1
  var reach=1'u64 shl int(v[1])
  for pass in 0..<n:
    let old=reach
    for i in 0..<n:if ((reach shr i) and 1)!=0:reach=reach or adj[i]
    if old==reach:break
  if reach!=all:return -1
  var order:array[MaxN,int];order[0]=int(v[1]);var used=1;var visited=1'u64 shl int(v[1])
  while used<n:
    var chosen=n
    for x in 0..<n:
      if ((visited shr x) and 1)==0:
        var wins=chosen==n
        if not wins:
          var k=used
          while k>0:
            dec k
            let xb=(adj[x] shr order[k]) and 1;let yb=(adj[chosen] shr order[k]) and 1
            if xb!=yb:wins=xb>yb;break
            if k==0:wins=x<chosen
        if wins:chosen=x
    order[used]=chosen;inc used;visited=visited or (1'u64 shl chosen)
  var fields:array[MaxFields,int64];fields[0]=int64(n)
  for i in 0..<n:fields[1+i]=int64(order[i])
  var certs=0;var at=n+2
  for i in 0..<n:
    for j in i+1..<n:
      for k in j+1..<n:
        let a=order[i];let b=order[j];let c=order[k]
        if ((adj[a] shr c) and 1)!=0 and ((adj[a] shr b) and 1)==0:
          var witness = -1
          for t in i+1..<j:
            let d=order[t]
            if ((adj[d] shr b) and 1)!=0 and ((adj[d] shr c) and 1)==0:witness=d;break
          fields[at]=int64(a);fields[at+1]=int64(b);fields[at+2]=int64(c);fields[at+3]=int64(witness);at+=4;inc certs
  fields[n+1]=int64(certs)
  if out.isNil or capacity<csize_t(8*at):return -2
  for i in 0..<at:put(out,8*i,fields[i])
  int64(8*at)
