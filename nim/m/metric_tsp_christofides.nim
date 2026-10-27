const MaxN=8
proc store(outp: ptr UncheckedArray[uint8], p:int, x:int64)=
  let bits=cast[uint64](x)
  for b in 0..<8: outp[p+b]=uint8((bits shr (8*b)) and 255)

proc metric_tsp_christofides*(input: ptr UncheckedArray[int64], length:csize_t,
    output: ptr UncheckedArray[uint8], capacity:csize_t):int64 {.cdecl,exportc:"metric_tsp_christofides".}=
  if input.isNil or length<2 or length>65:return -1
  let n0=input[0]
  if n0<1 or n0>MaxN or int64(length)!=1+n0*n0:return -1
  let n=int(n0);var d:array[MaxN,array[MaxN,int64]]
  for i in 0..<n:
    for j in 0..<n:
      let w=input[1+i*n+j]
      if w<0 or w>10000 or (i==j and w!=0):return -1
      d[i][j]=w
  for i in 0..<n:
    for j in 0..<n:
      if d[i][j]!=d[j][i]:return -1
      for k in 0..<n:if d[i][j]>d[i][k]+d[k][j]:return -1
  let bytes=8*(n+2)
  if output.isNil or capacity<csize_t(bytes):return -2
  var edges:array[28,tuple[w:int64,u,v:int]];var ec=0
  for i in 0..<n:for j in i+1..<n:edges[ec]=(d[i][j],i,j);inc ec
  for i in 0..<ec:for j in i+1..<ec:if edges[j]<edges[i]:swap(edges[i],edges[j])
  var parent:array[MaxN,int];for i in 0..<n:parent[i]=i
  var tree:array[MaxN,array[MaxN,bool]];var chosen=0
  for x in 0..<ec:
    let (w,u,v)=edges[x];discard w
    var a=u;var b=v;while parent[a]!=a:a=parent[a];while parent[b]!=b:b=parent[b]
    if a!=b:parent[b]=a;tree[u][v]=true;tree[v][u]=true;inc chosen
    if chosen==n-1:break
  var odd:array[MaxN,int];var on=0
  for i in 0..<n:var deg=0;for j in 0..<n:if tree[i][j]:inc deg;if deg mod 2==1:odd[on]=i;inc on
  let full=(1 shl on)-1;var dp:array[256,int64];var pick:array[256,int]
  for m in 0..<256:dp[m]=high(int64) div 4;pick[m]= -1
  dp[0]=0
  for mask in 1..full:
    var i=0;while (mask and (1 shl i))==0:inc i
    let rest=mask xor (1 shl i)
    for j in i+1..<on:
      if (rest and (1 shl j))!=0:
        let tail=rest xor (1 shl j);let value=dp[tail]+d[odd[i]][odd[j]]
        if value<dp[mask]:dp[mask]=value;pick[mask]=j
  var multi:array[MaxN,array[MaxN,int]]
  for i in 0..<n:for j in 0..<n:if tree[i][j]:multi[i][j]=1
  var mask=full
  while mask!=0:
    var i=0;while (mask and (1 shl i))==0:inc i
    let j=pick[mask];inc multi[odd[i]][odd[j]];inc multi[odd[j]][odd[i]];mask=mask xor (1 shl i) xor (1 shl j)
  var st:array[32,int];var top=1;st[0]=0;var rev:array[32,int];var rc=0
  while top>0:
    let v=st[top-1];var w= -1
    for x in 0..<n:if multi[v][x]>0:w=x;break
    if w<0:dec top;rev[rc]=st[top];inc rc
    else:dec multi[v][w];dec multi[w][v];st[top]=w;inc top
  var seen:array[MaxN,bool];var order:array[MaxN,int];var cnt=0
  for ix in countdown(rc-1,0):let v=rev[ix];if not seen[v]:seen[v]=true;order[cnt]=v;inc cnt
  var cost=0'i64;for i in 0..<n-1:cost+=d[order[i]][order[i+1]];cost+=d[order[n-1]][0]
  store(output,0,cost);for i in 0..<n:store(output,8*(i+1),int64(order[i]));store(output,8*(n+1),0);int64(bytes)
