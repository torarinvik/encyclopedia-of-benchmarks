## Delaunay-rooted reverse search over convex polygon triangulations.
const MaxN = 8
const MaxD = 20
const MaxStates = 132

type Context = object
  n, d: int
  points: array[16, int64]
  diagonals: array[MaxD, int] # packed as 8*u+v

proc orient(c: Context, a, b, z: int): int64 =
  (c.points[2*b]-c.points[2*a])*(c.points[2*z+1]-c.points[2*a+1]) -
    (c.points[2*b+1]-c.points[2*a+1])*(c.points[2*z]-c.points[2*a])

proc incircle(c: Context, a, b, z, d: int): int64 =
  let ax=c.points[2*a]-c.points[2*d]; let ay=c.points[2*a+1]-c.points[2*d+1]
  let bx=c.points[2*b]-c.points[2*d]; let by=c.points[2*b+1]-c.points[2*d+1]
  let cx=c.points[2*z]-c.points[2*d]; let cy=c.points[2*z+1]-c.points[2*d+1]
  let al=ax*ax+ay*ay; let bl=bx*bx+by*by; let cl=cx*cx+cy*cy
  al*(bx*cy-by*cx)-bl*(ax*cy-ay*cx)+cl*(ax*by-ay*bx)

proc unpack(c: Context, i: int): tuple[u,v:int] = (c.diagonals[i] div 8, c.diagonals[i] mod 8)
proc isBoundary(n,u,v:int): bool = v==u+1 or (u==0 and v==n-1)
proc edgeIndex(c:Context,u,v:int): int =
  for i in 0..<c.d:
    let e=unpack(c,i)
    if e.u==u and e.v==v: return i
  -1
proc edgesCross(a,b:tuple[u,v:int]):bool =
  (a.u<b.u and b.u<a.v and a.v<b.v) or (b.u<a.u and a.u<b.v and b.v<a.v)

proc adjacency(c:Context,mask:uint32):array[MaxN,uint16] =
  var rows:array[MaxN,uint16]
  for u in 0..<c.n:
    let v=(u+1) mod c.n
    rows[u]=rows[u] or (1'u16 shl v); rows[v]=rows[v] or (1'u16 shl u)
  for i in 0..<c.d:
    if (mask and (1'u32 shl i))!=0:
      let e=unpack(c,i);rows[e.u]=rows[e.u] or (1'u16 shl e.v);rows[e.v]=rows[e.v] or (1'u16 shl e.u)
  rows

proc triangleCount(c:Context,mask:uint32):int =
  let rows=adjacency(c,mask)
  for a in 0..<c.n:
    for b in a+1..<c.n:
      for z in b+1..<c.n:
        if (rows[a] and (1'u16 shl b))!=0 and (rows[b] and (1'u16 shl z))!=0 and (rows[a] and (1'u16 shl z))!=0: inc result

proc commonOpposites(c:Context,mask:uint32,edge:int):tuple[ok:bool,inside,outside:int] =
  let rows=adjacency(c,mask);let e=unpack(c,edge);let common=rows[e.u] and rows[e.v]
  var inside= -1;var outside= -1;var found=0
  for w in 0..<c.n:
    if (common and (1'u16 shl w))!=0:
      if e.u<w and w<e.v: inside=w else: outside=w
      inc found
  (found==2 and inside>=0 and outside>=0,inside,outside)

proc flipState(c:Context,mask:uint32,edge:int,requireLawson:bool):int64 =
  let e=unpack(c,edge);let opposite=commonOpposites(c,mask,edge)
  if not opposite.ok: return -1
  if requireLawson and incircle(c,e.u,opposite.inside,e.v,opposite.outside)<=0:return -1
  let ix=edgeIndex(c,min(opposite.inside,opposite.outside),max(opposite.inside,opposite.outside))
  if ix<0:return -1
  int64((mask and not (1'u32 shl edge)) or (1'u32 shl ix))

proc parentState(c:Context,mask:uint32):int64 =
  for edge in 0..<c.d:
    if (mask and (1'u32 shl edge))!=0:
      let p=flipState(c,mask,edge,true)
      if p>=0:return p
  -1

proc validRoot(c:Context,mask:uint32):bool =
  if triangleCount(c,mask)!=c.n-2:return false
  let rows=adjacency(c,mask)
  for a in 0..<c.n:
    for b in a+1..<c.n:
      for z in b+1..<c.n:
        if (rows[a] and (1'u16 shl b))!=0 and (rows[b] and (1'u16 shl z))!=0 and (rows[a] and (1'u16 shl z))!=0:
          for q in 0..<c.n:
            if q!=a and q!=b and q!=z and incircle(c,a,b,z,q)>0:return false
  true

proc reverseSearch(c:Context,root:uint32):int64 =
  var states:array[MaxStates,uint32];var cursor:array[MaxStates,int];var top=0;var count=1;states[0]=root
  while top>=0:
    if cursor[top]>=c.d:
      if top==0:break
      dec top;continue
    let edge=cursor[top];inc cursor[top]
    if (states[top] and (1'u32 shl edge))==0:continue
    let child=flipState(c,states[top],edge,false)
    if child<0 or parentState(c,uint32(child))!=int64(states[top]):continue
    if count>=MaxStates:return -1
    inc count;inc top;states[top]=uint32(child);cursor[top]=0
  int64(count)

proc delaunay_rooted_triangulation_reverse_search*(input:ptr UncheckedArray[int64],length:csize_t):int64
    {.cdecl,exportc:"delaunay_rooted_triangulation_reverse_search".} =
  if input.isNil or length<2 or length>29:return -1
  let n64=input[0]
  if n64<3 or n64>MaxN or int64(length)!=4*n64-4:return -1
  let n=int(n64);var c=Context(n:n)
  for i in 0..<n:
    let x=input[1+2*i];let y=input[2+2*i]
    if x< -50 or x>50 or y< -50 or y>50:return -1
    c.points[2*i]=x;c.points[2*i+1]=y
  for a in 0..<n:
    for b in a+1..<n:
      for z in b+1..<n:
        if orient(c,a,b,z)<=0:return -1
  for a in 0..<n:
    for b in a+1..<n:
      for z in b+1..<n:
        for q in z+1..<n:
          if incircle(c,a,b,z,q)==0:return -1
  for u in 0..<n:
    for v in u+1..<n:
      if not isBoundary(n,u,v):c.diagonals[c.d]=8*u+v;inc c.d
  let at=1+2*n
  if input[at]!=int64(n-3):return -1
  var root:uint32=0;var previous=(-1,-1)
  for i in 0..<n-3:
    let u64=input[at+1+2*i];let v64=input[at+2+2*i]
    if u64<0 or u64>=v64 or v64>=n64:return -1
    let edge=(int(u64),int(v64))
    if isBoundary(n,edge[0],edge[1]) or (i>0 and (edge[0]<previous[0] or (edge[0]==previous[0] and edge[1]<=previous[1]))):return -1
    let ix=edgeIndex(c,edge[0],edge[1]);if ix<0:return -1
    root=root or (1'u32 shl ix);previous=edge
  var seen=0
  for i in 0..<c.d:
    if (root and (1'u32 shl i))!=0:
      inc seen
      for j in i+1..<c.d:
        if (root and (1'u32 shl j))!=0 and edgesCross(unpack(c,i),unpack(c,j)):return -1
  if seen!=n-3 or not validRoot(c,root):return -1
  reverseSearch(c,root)
