# Clean-room exact Delaunay graph construction by empty circumcircles.
const MaxN=8;MaxFields=37
type Point=tuple[x,y:int64]
proc orient(a,b,c:Point):int64=(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)
proc circle(a,b,c,d:Point):int64=
  let ax=a.x-d.x;let ay=a.y-d.y;let bx=b.x-d.x;let by=b.y-d.y;let cx=c.x-d.x;let cy=c.y-d.y
  let aa=ax*ax+ay*ay;let bb=bx*bx+by*by;let cc=cx*cx+cy*cy
  aa*(bx*cy-by*cx)-bb*(ax*cy-ay*cx)+cc*(ax*by-ay*bx)
proc put(out:ptr UncheckedArray[uint8],at:int,x:int64)=
  let bits=cast[uint64](x)
  for i in 0..<8:out[at+i]=uint8((bits shr (8*i)) and 255)
proc voronoi_delaunay_empty_circle*(v:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"voronoi_delaunay_empty_circle".}=
  if v.isNil or length<7 or length>17 or v[0]<3 or v[0]>MaxN:return -1
  let n=int(v[0]);if int(length)!=1+2*n:return -1
  var points:array[MaxN,Point]
  for i in 0..<n:
    let x=v[1+2*i];let y=v[2+2*i]
    if x < -50 or x > 50 or y < -50 or y > 50:return -1
    for j in 0..<i:if points[j].x==x and points[j].y==y:return -1
    points[i]=(x,y)
  for a in 0..<n:for b in a+1..<n:for c in b+1..<n:if orient(points[a],points[b],points[c])==0:return -1
  for a in 0..<n:for b in a+1..<n:for c in b+1..<n:for d in c+1..<n:if circle(points[a],points[b],points[c],points[d])==0:return -1
  var edges:array[MaxN,array[MaxN,bool]]
  for a in 0..<n:
    for b in a+1..<n:
      for c in b+1..<n:
        let o=orient(points[a],points[b],points[c]);var empty=true
        for d in 0..<n:
          if d!=a and d!=b and d!=c:
            let z=circle(points[a],points[b],points[c],points[d])
            if (o>0 and z>0) or (o<0 and z<0):empty=false;break
        if empty:edges[a][b]=true;edges[b][a]=true;edges[a][c]=true;edges[c][a]=true;edges[b][c]=true;edges[c][b]=true
  var fields:array[MaxFields,int64];var at=1;var m=0
  for a in 0..<n:for b in a+1..<n:if edges[a][b]:fields[at]=int64(a);fields[at+1]=int64(b);at+=2;inc m
  fields[0]=int64(m);let bytes=8*at
  if out.isNil or capacity<csize_t(bytes):return -2
  for i in 0..<at:put(out,8*i,fields[i])
  int64(bytes)
