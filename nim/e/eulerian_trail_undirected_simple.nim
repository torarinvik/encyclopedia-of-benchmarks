const MaxV=10
const MaxE=45
proc dfs(u:int,neighbors:array[MaxV,array[MaxE,int]],degree:array[MaxV,int],seen:var array[MaxV,array[MaxV,bool]],path:var array[MaxE+1,int64],count:var int)=
  path[count]=int64(u);inc count
  for i in 0..<degree[u]:
    let v=neighbors[u][i]
    if not seen[u][v]: seen[u][v]=true;seen[v][u]=true;dfs(v,neighbors,degree,seen,path,count)
proc put(outp:ptr UncheckedArray[uint8],slot:int,value:int64)=
  let bits=cast[uint64](value)
  for i in 0..<8: outp[slot*8+i]=uint8((bits shr (i*8)) and 255)
proc eulerian_trail_undirected_simple*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"eulerian_trail_undirected_simple".}=
  if input==nil or length<2:return -1
  let n0=input[0];let m0=input[1]
  if n0<2 or n0>MaxV or m0<0 or m0>MaxE:return -1
  let n=int(n0);let m=int(m0);if int(length)!=2+2*m:return -1
  var neighbors:array[MaxV,array[MaxE,int]];var degree:array[MaxV,int];var adjacent:array[MaxV,array[MaxV,bool]]
  for i in 0..<m:
    let a=input[2+2*i];let b=input[3+2*i]
    if a<0 or b<0 or a>=n0 or b>=n0 or a==b:return -1
    let u=int(a);let v=int(b);if adjacent[u][v]:return -1
    adjacent[u][v]=true;adjacent[v][u]=true;neighbors[u][degree[u]]=v;inc degree[u];neighbors[v][degree[v]]=u;inc degree[v]
  var odd=0;var start=1
  for v in 0..<n:
    if degree[v] mod 2==1:inc odd;start=v
  if odd!=0 and odd!=2:return -1
  let status=if odd==0:1 else:2
  if status==1:start=1
  if m>0:
    if status==1 and degree[1]==0:return -1
    var reached:array[MaxV,bool];var stack:array[MaxV,int];var top=0;stack[top]=start;inc top;reached[start]=true
    while top>0:
      dec top;let u=stack[top]
      for i in 0..<degree[u]:let v=neighbors[u][i];if not reached[v]:reached[v]=true;stack[top]=v;inc top
    for v in 0..<n:if degree[v]>0 and not reached[v]:return -1
  var seen:array[MaxV,array[MaxV,bool]];var path:array[MaxE+1,int64];var count=0;dfs(start,neighbors,degree,seen,path,count)
  if count!=m+1:return -1
  let bytes=(2+count)*8
  if output==nil or int(capacity)<bytes:return -2
  put(output,0,int64(status));put(output,1,int64(count));for i in 0..<count:put(output,2+i,path[i])
  int64(bytes)
