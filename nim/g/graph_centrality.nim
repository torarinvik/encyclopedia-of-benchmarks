proc put(o: ptr UncheckedArray[uint8], a: int, v: int64) =
  let b = cast[uint64](v)
  for i in 0 ..< 8: o[a*8+i] = uint8((b shr (i*8)) and 255)
proc graph_centrality*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "graph_centrality".} =
  if input == nil or length < 2: return -1
  let nn=input[0]; let ee=input[1]
  if nn<1 or nn>16 or ee<0 or ee>nn*(nn-1) or length != csize_t(2+3*ee): return -1
  let n=int(nn); let e=int(ee); const inf=int64.high
  var d: array[16,array[16,int64]]
  for i in 0..<n:
    for j in 0..<n:
      d[i][j] = (if i==j: 0'i64 else: inf)
  for z in 0..<e:
    let a=input[2+3*z];let b=input[3+3*z];let w=input[4+3*z]
    if a<0 or a>=nn or b<0 or b>=nn or a==b or w<1 or w>1000000 or d[int(a)][int(b)]!=inf:return -1
    d[int(a)][int(b)]=w
  for k in 0..<n:
    for i in 0..<n:
      if d[i][k]!=inf:
        for j in 0..<n:
          if d[k][j]!=inf and d[i][k]+d[k][j]<d[i][j]:d[i][j]=d[i][k]+d[k][j]
  var c= -1'i64;var m= -1'i64;var be=inf;var bh= -1.0
  if n==1:c=0;m=0
  else:
    for i in 0..<n:
      var reachable=false;var ec=0'i64;var h=0.0
      for j in 0..<n:
        if i!=j and d[i][j]!=inf:
          reachable=true;ec=max(ec,d[i][j]);h+=1.0/float64(d[i][j])
      if reachable and ec<be:be=ec;c=int64(i)
      if reachable and h>bh:bh=h;m=int64(i)
  if output==nil or capacity<16:return -2
  put(output,0,c);put(output,1,m);16
