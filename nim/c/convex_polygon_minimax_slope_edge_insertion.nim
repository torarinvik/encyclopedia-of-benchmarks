type
  InputPtr = ptr UncheckedArray[int64]
  Point = object
    x, y, z: int64
  Triangle = object
    a, b, c: int
  Slope = object
    num, den: int64

const MaxN = 4
const MaxLength = 14

proc orient(p: array[MaxN, Point], a, b, c: int): int64 =
  (p[b].x-p[a].x)*(p[c].y-p[a].y)-(p[b].y-p[a].y)*(p[c].x-p[a].x)

proc slope(p: array[MaxN, Point], t: Triangle): Slope =
  let a=p[t.a]; let b=p[t.b]; let c=p[t.c]
  let dx1=b.x-a.x; let dy1=b.y-a.y; let dz1=b.z-a.z
  let dx2=c.x-a.x; let dy2=c.y-a.y; let dz2=c.z-a.z
  let det=dx1*dy2-dx2*dy1; let gx=dz1*dy2-dz2*dy1; let gy=dx1*dz2-dz1*dx2
  Slope(num: gx*gx+gy*gy, den: det*det)

proc cmp(a, b: Slope): int =
  let x=a.num*b.den; let y=b.num*a.den
  if x > y: 1 elif x < y: -1 else: 0

proc maximum(p: array[MaxN, Point], a, b: Triangle): Slope =
  let x=slope(p,a); let y=slope(p,b)
  if cmp(x,y) >= 0: x else: y

proc anchor(p: array[MaxN, Point], t: Triangle, q: int): bool =
  let a=p[t.a]; let b=p[t.b]; let c=p[t.c]
  let dx1=b.x-a.x; let dy1=b.y-a.y; let dz1=b.z-a.z
  let dx2=c.x-a.x; let dy2=c.y-a.y; let dz2=c.z-a.z
  let det=dx1*dy2-dx2*dy1; let gx=dz1*dy2-dz2*dy1; let gy=dx1*dz2-dz1*dx2
  if gx == 0 and gy == 0: return false
  var other: array[2, int]; var used=0
  for v in [t.a,t.b,t.c]:
    if v != q: other[used]=v; inc used
  let sign = (if det > 0: 1'i64 else: -1'i64)
  let dx = -gx*sign; let dy = -gy*sign
  let ux=p[other[0]].x-p[q].x; let uy=p[other[0]].y-p[q].y
  let vx=p[other[1]].x-p[q].x; let vy=p[other[1]].y-p[q].y
  let turn=ux*vy-uy*vx; let side=(if turn > 0: 1'i64 else: -1'i64)
  side*(ux*dy-uy*dx) >= 0 and side*(dx*vy-dy*vx) >= 0

proc crosses(p: array[MaxN, Point], a,b,c,d: int): bool =
  orient(p,a,b,c)*orient(p,a,b,d) < 0 and orient(p,c,d,a)*orient(p,c,d,b) < 0

proc volume6(p: array[MaxN, Point]): int64 =
  let ax=p[1].x-p[0].x; let ay=p[1].y-p[0].y; let az=p[1].z-p[0].z
  let bx=p[2].x-p[0].x; let by=p[2].y-p[0].y; let bz=p[2].z-p[0].z
  let cx=p[3].x-p[0].x; let cy=p[3].y-p[0].y; let cz=p[3].z-p[0].z
  ax*(by*cz-bz*cy)-ay*(bx*cz-bz*cx)+az*(bx*cy-by*cx)

proc rank(p: array[MaxN, Point], n: int, target: Slope): int64 =
  var all: array[4, Slope]; var count=0
  for a in 0 ..< n:
    for b in a+1 ..< n:
      for c in b+1 ..< n:
        all[count]=slope(p,Triangle(a:a,b:b,c:c)); inc count
  var distinct=0
  for i in 0 ..< count:
    if cmp(all[i],target) < 0:
      var seen=false
      for j in 0 ..< i:
        if cmp(all[j],all[i]) == 0: seen=true
      if not seen: inc distinct
  int64(distinct+1)

proc convex_polygon_minimax_slope_edge_insertion*(input: InputPtr, length: csize_t): int64
  {.cdecl, exportc: "convex_polygon_minimax_slope_edge_insertion".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxLength): return -1
  let raw=input[0]; if raw < 3 or raw > 4: return -1
  let n=int(raw); if int(length) != 1+3*n: return -1
  var p: array[MaxN, Point]
  for i in 0 ..< n:
    p[i]=Point(x:input[1+3*i],y:input[2+3*i],z:input[3+3*i])
    if p[i].x < -8 or p[i].x > 8 or p[i].y < -8 or p[i].y > 8 or p[i].z < -8 or p[i].z > 8: return -1
  var area=0'i64
  for i in 0 ..< n:
    let j=(i+1) mod n; area += p[i].x*p[j].y-p[i].y*p[j].x
  if area == 0: return -1
  let sign=(if area > 0: 1'i64 else: -1'i64)
  for a in 0 ..< n:
    for b in a+1 ..< n:
      for c in b+1 ..< n:
        if orient(p,a,b,c) == 0: return -1
  for e in 0 ..< n:
    let j=(e+1) mod n
    for k in 0 ..< n:
      if k != e and k != j and sign*orient(p,e,j,k) <= 0: return -1
  if n == 4 and volume6(p) == 0: return -1
  let fan=[Triangle(a:0,b:1,c:2),Triangle(a:0,b:2,c:3)]
  var worst=if n == 3: slope(p,fan[0]) else: maximum(p,fan[0],fan[1])
  if n == 4:
    var done=false
    for t in fan:
      if done: break
      if cmp(slope(p,t),worst) != 0: continue
      let v=[t.a,t.b,t.c]
      for k in 0 .. 2:
        if done: break
        let q=v[k]; if not anchor(p,t,q): continue
        var o: array[2,int]; var used=0; var s=4
        for j in 0 .. 2:
          if j != k: o[used]=v[j]; inc used
        for j in 0 ..< 4:
          if j != v[0] and j != v[1] and j != v[2]: s=j
        if not crosses(p,q,s,o[0],o[1]): continue
        let candidate=maximum(p,Triangle(a:q,b:s,c:o[0]),Triangle(a:q,b:s,c:o[1]))
        if cmp(candidate,worst) < 0: worst=candidate; done=true
  rank(p,n,worst)
