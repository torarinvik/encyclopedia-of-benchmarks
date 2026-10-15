const MaxN=16
const MaxM=64
proc root(p:var array[MaxN,int],x0:int):int =
  var x=x0
  while p[x]!=x:p[x]=p[p[x]];x=p[x]
  x
proc boruvkas_minimum_spanning_tree*(input:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"boruvkas_minimum_spanning_tree".} =
  if input==nil or length<2:return -1
  let nv=input[0];let mv=input[1]
  if nv<2 or nv>MaxN or mv<nv-1 or mv>MaxM or mv>nv*(nv-1) div 2:return -1
  let n=int(nv);let m=int(mv);if length!=csize_t(2+3*m):return -1
  var w:array[MaxN*MaxN,int64];for i in 0..<MaxN*MaxN:w[i]=high(int64)
  for k in 0..<m:
    let u=input[2+3*k];let v=input[3+3*k];let x=input[4+3*k]
    if u<1 or u>nv or v<1 or v>nv or u==v or x<1 or x>100 or w[(int(u)-1)*MaxN+int(v)-1]!=high(int64):return -1
    w[(int(u)-1)*MaxN+int(v)-1]=x;w[(int(v)-1)*MaxN+int(u)-1]=x
  var p:array[MaxN,int];for i in 0..<n:p[i]=i
  var components=n;var total=0'i64
  while components>1:
    var bu,bv:array[MaxN,int];var bw:array[MaxN,int64]
    for i in 0..<MaxN:bu[i]= -1;bv[i]= -1;bw[i]=high(int64)
    for u in 0..<n:for v in u+1..<n:
      let x=w[u*MaxN+v]
      if x!=high(int64):
        let a=root(p,u);let b=root(p,v)
        if a!=b:
          if x<bw[a]:bw[a]=x;bu[a]=u;bv[a]=v
          if x<bw[b]:bw[b]=x;bu[b]=u;bv[b]=v
    var merged=false
    for r in 0..<n:
      if bu[r]>=0:
        let a=root(p,bu[r]);let b=root(p,bv[r])
        if a!=b:p[a]=b;dec components;total+=bw[r];merged=true
    if not merged:return -1
  total
