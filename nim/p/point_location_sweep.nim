import std/[algorithm, sequtils]

type
  Point = tuple[x, y: int64]
  Edge = tuple[u, v: int, face: int64]
  Event = tuple[x, kind: int64, id: int]

proc orient(a, b, c: Point): int64 = (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)
proc between(x, a, b: int64): bool = x >= min(a,b) and x <= max(a,b)
proc onSegment(a,b,p: Point): bool = orient(a,b,p)==0 and between(p.x,a.x,b.x) and between(p.y,a.y,b.y)
proc intersects(a,b,c,d: Point): bool =
  let o1=orient(a,b,c); let o2=orient(a,b,d); let o3=orient(c,d,a); let o4=orient(c,d,b)
  if (o1==0 and onSegment(a,b,c)) or (o2==0 and onSegment(a,b,d)) or (o3==0 and onSegment(c,d,a)) or (o4==0 and onSegment(c,d,b)): return true
  ((o1<0 and o2>0) or (o1>0 and o2<0)) and ((o3<0 and o4>0) or (o3>0 and o4<0))
proc endpoints(points: seq[Point], edges: seq[Edge], e: int): tuple[l,r: Point] =
  let a=points[edges[e].u]; let b=points[edges[e].v]
  if a.x < b.x: (a,b) else: (b,a)
proc height(points: seq[Point], edges: seq[Edge], e: int, x: int64): tuple[num,den:int64] =
  let (l,r)=endpoints(points,edges,e); let d=r.x-l.x
  (l.y*d+(r.y-l.y)*(x-l.x),d)
proc edgeLess(points: seq[Point], edges: seq[Edge], a,b: int, x:int64): bool =
  let (na,da)=height(points,edges,a,x); let (nb,db)=height(points,edges,b,x)
  if na*db != nb*da: return na*db < nb*da
  let (la,ra)=endpoints(points,edges,a); let (lb,rb)=endpoints(points,edges,b)
  let sa=(ra.y-la.y)*(rb.x-lb.x); let sb=(rb.y-lb.y)*(ra.x-la.x)
  if sa != sb: sa < sb else: a < b
proc point_location_sweep_impl(a: ptr UncheckedArray[int64], length: int): int64 =
  if a==nil or length<4 or length>141: return -1
  let n=a[0]; let m=a[1]; let q=a[2]; let f=a[3]
  if n<2 or n>16 or m<1 or m>24 or q<0 or q>16 or f<1 or f>16 or length != 4+2*int(n)+3*int(m)+2*int(q): return -1
  var pos=4; var points: seq[Point] = @[]
  for i in 0..<int(n):
    let p:Point=(a[pos],a[pos+1]); pos+=2
    if p.x < -300 or p.x > 300 or p.y < -300 or p.y > 300: return -1
    for old in points:
      if old.x==p.x: return -1
    points.add(p)
  var edges:seq[Edge] = @[]
  for i in 0..<int(m):
    let u=a[pos];let v=a[pos+1];let face=a[pos+2];pos+=3
    if u<0 or u>=n or v<0 or v>=n or u==v or face < -1 or face>=f:return -1
    for old in edges:
      if (old.u==int(u) and old.v==int(v)) or (old.u==int(v) and old.v==int(u)):return -1
    edges.add((int(u),int(v),face))
  for i in 0..<edges.len:
    for j in 0..<i:
      let e=edges[i];let g=edges[j]
      var shared = -1
      if e.u==g.u or e.u==g.v: shared=e.u
      elif e.v==g.u or e.v==g.v: shared=e.v
      if shared>=0:
        let oi=if e.u==shared:e.v else:e.u
        let oj=if g.u==shared:g.v else:g.u
        if orient(points[shared],points[oi],points[oj])==0:return -1
      elif intersects(points[e.u],points[e.v],points[g.u],points[g.v]):return -1
  var queries:seq[tuple[x,y:int64]] = @[]
  for i in 0..<int(q):
    let x=a[pos];let y=a[pos+1];pos+=2
    if x < -300 or x > 300 or y < -300 or y > 300:return -1
    for p in points:
      if p.x==x:return -1
    queries.add((x,y))
  var events:seq[Event] = @[]
  for e in 0..<edges.len:
    let (l,r)=endpoints(points,edges,e);events.add((l.x,1'i64,e));events.add((r.x,0'i64,e))
  for i,p in queries.pairs:events.add((p.x,2'i64,i))
  events.sort(proc(a,b:Event):int =
    if a.x!=b.x: cmp(a.x,b.x) elif a.kind!=b.kind: cmp(a.kind,b.kind) else: cmp(a.id,b.id))
  var active:seq[int] = @[];var response=newSeq[int64](queries.len)
  for event in events:
    if event.kind==0:
      let k=active.find(event.id);if k<0:return -1;active.delete(k)
    elif event.kind==1:
      var k=0;while k<active.len and edgeLess(points,edges,active[k],event.id,event.x):inc k
      active.insert(event.id,k)
    else:
      let (x,y)=queries[event.id];var lo=0;var hi=active.len
      while lo<hi:
        let mid=(lo+hi) div 2;let (num,den)=height(points,edges,active[mid],x)
        if num<y*den:lo=mid+1 else:hi=mid
      if lo<active.len:
        let (num,den)=height(points,edges,active[lo],x)
        if num==y*den:response[event.id]=f+int64(active[lo])+1
        elif lo>0 and edges[active[lo-1]].face>=0:response[event.id]=edges[active[lo-1]].face+1
      elif lo>0 and edges[active[lo-1]].face>=0:response[event.id]=edges[active[lo-1]].face+1
  for i,r in response.pairs: result += int64(i+1)*r
proc point_location_sweep*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "point_location_sweep".} =
  point_location_sweep_impl(values,int(length))
