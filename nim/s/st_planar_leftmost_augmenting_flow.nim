const MaxN=6;const MaxM=10;const MaxInput=60
proc putI64(output:ptr UncheckedArray[uint8],value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[b]=uint8((bits shr (b*8)) and 255'u64)
proc st_planar_leftmost_augmenting_flow*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"st_planar_leftmost_augmenting_flow".}=
  if input==nil or length<4 or length>MaxInput:return -1
  let n0=input[0];let m0=input[1];let s0=input[2];let t0=input[3]
  if n0<2 or n0>MaxN or m0<1 or m0>MaxM or s0<0 or s0>=n0 or t0<0 or t0>=n0 or s0==t0:return -1
  let n=int(n0);let m=int(m0);let s=int(s0);let t=int(t0);if length<csize_t(4+3*m):return -1
  var eu,ev,capv:array[MaxM,int];var pairSeen:array[MaxN,array[MaxN,bool]];var at=4
  for e in 0..<m:
    let u=input[at];let v=input[at+1];let c=input[at+2];at+=3
    if u<0 or u>=n0 or v<0 or v>=n0 or u==v or c<0 or c>5:return -1
    if pairSeen[int(u)][int(v)] or pairSeen[int(v)][int(u)]:return -1
    pairSeen[int(u)][int(v)]=true;pairSeen[int(v)][int(u)]=true;eu[e]=int(u);ev[e]=int(v);capv[e]=int(c)
  var degree:array[MaxN,int];var rot:array[MaxN,array[MaxN,int]];var occ:array[MaxM,array[2,int]];var rotSeen:array[MaxN,array[MaxM,bool]]
  for x in 0..<n:
    if at>=int(length):return -1
    let d=input[at];at+=1;if d<0 or d>=n or at+int(d)>int(length):return -1;degree[x]=int(d)
    for j in 0..<degree[x]:
      let ee=input[at];at+=1;if ee<0 or ee>=m0:return -1;let e=int(ee)
      if rotSeen[x][e]:return -1;rotSeen[x][e]=true;rot[x][j]=e
      if eu[e]==x:occ[e][0]+=1 elif ev[e]==x:occ[e][1]+=1 else:return -1
  if at!=int(length):return -1
  for e in 0..<m:if occ[e][0]!=1 or occ[e][1]!=1:return -1
  var connected:array[MaxN,bool];var q:array[MaxN,int];var head=0;var tail=0;connected[s]=true;q[tail]=s;tail+=1
  while head<tail:
    let x=q[head];head+=1
    for e in 0..<m:
      let y=if eu[e]==x:ev[e] elif ev[e]==x:eu[e] else:-1
      if y>=0 and not connected[y]:connected[y]=true;q[tail]=y;tail+=1
  for x in 0..<n:if not connected[x]:return -1
  var flow:array[MaxM,int];var total=0
  while true:
    var visited:array[MaxN,bool];var parent,parentEdge,parentDir,next:array[MaxN,int];for x in 0..<n:parent[x] = -1;parentEdge[x] = -1
    var stack:array[MaxN,int];var top=0;visited[s]=true;stack[top]=s;top+=1
    while top>0 and not visited[t]:
      let x=stack[top-1]
      if next[x]>=degree[x]:top-=1;continue
      let e=rot[x][next[x]];next[x]+=1;let y=if eu[e]==x:ev[e] else:eu[e];let rem=if eu[e]==x:capv[e]-flow[e] else:flow[e]
      if rem>0 and not visited[y]:visited[y]=true;parent[y]=x;parentEdge[y]=e;parentDir[y]=if eu[e]==x:1 else:-1;stack[top]=y;top+=1
    if not visited[t]:break
    var delta=high(int);var y=t
    while y!=s:let x=parent[y];let e=parentEdge[y];let rem=if eu[e]==x:capv[e]-flow[e] else:flow[e];delta=min(delta,rem);y=x
    y=t;while y!=s:let e=parentEdge[y];flow[e]+=parentDir[y]*delta;y=parent[y]
    total+=delta
  if output==nil or capacity<8:return -2
  putI64(output,int64(total));8
