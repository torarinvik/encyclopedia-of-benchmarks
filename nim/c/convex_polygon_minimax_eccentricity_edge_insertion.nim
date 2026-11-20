const
  MinN = 3
  MaxN = 6
  MaxLength = 14
  MaxTri = 4
  MaxAll = 14
  MaxDiag = 9
  MaxTriples = 20

type
  Point = object
    x, y: int64
  Triangle = object
    a, b, c: int
  Triangulation = object
    triangles: array[MaxTri, Triangle]
    count: int
    edges: uint64
  Fraction = object
    num, den: int64
  Metrics = object
    maximum: Fraction
    worst: uint64

proc orient(a, b, c: Point): int64 =
  (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)

proc gcd64(a0, b0: int64): int64 =
  var a=a0
  var b=b0
  while b != 0:
    let r=a mod b
    a=b
    b=r
  a

proc fraction(num, den: int64): Fraction =
  let divisor=gcd64(num,den)
  Fraction(num:num div divisor,den:den div divisor)

proc compare(a,b: Fraction): int =
  let left=a.num*b.den
  let right=b.num*a.den
  if left<right: -1
  elif left>right: 1
  else: 0

proc edgeBit(a,b: int): uint64 =
  let lo=min(a,b)
  let hi=max(a,b)
  1'u64 shl (lo*MaxN+hi)

proc properCross(p: array[MaxN,Point], a,b,c,d: int): bool =
  orient(p[a],p[b],p[c])*orient(p[a],p[b],p[d])<0 and
    orient(p[c],p[d],p[a])*orient(p[c],p[d],p[b])<0

proc insideTriangle(p: array[MaxN,Point], t: Triangle, v: int): bool =
  let direction=orient(p[t.a],p[t.b],p[t.c])
  orient(p[t.a],p[t.b],p[v])*direction>0 and
    orient(p[t.b],p[t.c],p[v])*direction>0 and
    orient(p[t.c],p[t.a],p[v])*direction>0

proc triangleScore(p: array[MaxN,Point], t: Triangle,
                   sides: var array[3,int64]): Fraction =
  let a=p[t.a]
  let b=p[t.b]
  let c=p[t.c]
  sides[0]=(b.x-c.x)*(b.x-c.x)+(b.y-c.y)*(b.y-c.y)
  sides[1]=(c.x-a.x)*(c.x-a.x)+(c.y-a.y)*(c.y-a.y)
  sides[2]=(a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y)
  var largest=0
  if sides[1]>sides[largest]: largest=1
  if sides[2]>sides[largest]: largest=2
  let other=sides[0]+sides[1]+sides[2]-sides[largest]
  if sides[largest]<=other: return Fraction(num:0,den:1)
  let area=abs(orient(a,b,c))
  let difference=sides[largest]-other
  fraction(sides[largest]*difference*difference,16*area*area)

proc triangleId(a,b,c,n: int): int =
  var id=0
  for x in 0 ..< n:
    for y in x+1 ..< n:
      for z in y+1 ..< n:
        if x==a and y==b and z==c: return id
        inc id
  0

proc evaluate(p: array[MaxN,Point], n: int, t: Triangulation): Metrics =
  var result=Metrics(maximum:Fraction(num:0,den:1),worst:0)
  for i in 0 ..< t.count:
    var sides: array[3,int64]
    let score=triangleScore(p,t.triangles[i],sides)
    let comparison=compare(score,result.maximum)
    let bit=1'u64 shl triangleId(t.triangles[i].a,t.triangles[i].b,t.triangles[i].c,n)
    if comparison>0:
      result.maximum=score
      result.worst=bit
    elif comparison==0:
      result.worst=result.worst or bit
  result

proc improves(a,b: Metrics): bool =
  let comparison=compare(a.maximum,b.maximum)
  comparison<0 or (comparison==0 and a.worst!=b.worst and (a.worst and b.worst)==a.worst)

proc popcount(value: uint64): int =
  var bits=value
  var count=0
  while bits!=0:
    bits=bits and (bits-1)
    inc count
  count

proc preferable(a,b: Metrics): bool =
  let comparison=compare(a.maximum,b.maximum)
  if comparison!=0: return comparison<0
  let ac=popcount(a.worst)
  let bc=popcount(b.worst)
  if ac!=bc: return ac<bc
  a.worst<b.worst

proc enumerate(p: array[MaxN,Point], n: int,
               output: var array[MaxAll,Triangulation]): int =
  var da,db: array[MaxDiag,int]
  var diagonalCount=0
  for a in 0 ..< n:
    for b in a+2 ..< n:
      if a==0 and b==n-1: continue
      da[diagonalCount]=a
      db[diagonalCount]=b
      inc diagonalCount
  var boundary=0'u64
  for a in 0 ..< n: boundary=boundary or edgeBit(a,(a+1) mod n)
  var total=0
  for mask in 0 ..< (1 shl diagonalCount):
    var count=0
    for i in 0 ..< diagonalCount:
      if ((mask shr i) and 1)!=0: inc count
    if count!=n-3: continue
    var crossing=false
    for i in 0 ..< diagonalCount:
      if crossing: break
      if ((mask shr i) and 1)==0: continue
      for j in i+1 ..< diagonalCount:
        if ((mask shr j) and 1)!=0 and properCross(p,da[i],db[i],da[j],db[j]):
          crossing=true
          break
    if crossing: continue
    var edges=boundary
    for i in 0 ..< diagonalCount:
      if ((mask shr i) and 1)!=0: edges=edges or edgeBit(da[i],db[i])
    var faces: array[MaxTri,Triangle]
    var faceCount=0
    for a in 0 ..< n:
      for b in a+1 ..< n:
        for c in b+1 ..< n:
          if (edges and edgeBit(a,b))==0 or (edges and edgeBit(b,c))==0 or (edges and edgeBit(c,a))==0: continue
          var contains=false
          for v in 0 ..< n:
            if v!=a and v!=b and v!=c and insideTriangle(p,Triangle(a:a,b:b,c:c),v):
              contains=true
              break
          if not contains and faceCount<MaxTri:
            faces[faceCount]=Triangle(a:a,b:b,c:c)
            inc faceCount
    if faceCount==n-2 and total<MaxAll:
      output[total]=Triangulation(triangles:faces,count:faceCount,edges:edges)
      inc total
  total

proc rankScore(p: array[MaxN,Point], n: int, target: Fraction): int64 =
  var seen: array[MaxTriples,Fraction]
  var count=0
  for a in 0 ..< n:
    for b in a+1 ..< n:
      for c in b+1 ..< n:
        var sides: array[3,int64]
        let score=triangleScore(p,Triangle(a:a,b:b,c:c),sides)
        if compare(score,target)>=0: continue
        var duplicate=false
        for i in 0 ..< count:
          if compare(score,seen[i])==0: duplicate=true; break
        if not duplicate:
          seen[count]=score
          inc count
  int64(count+1)

proc solve(p: array[MaxN,Point], n: int): int64 =
  var all: array[MaxAll,Triangulation]
  let total=enumerate(p,n,all)
  var fan: Triangulation
  for k in 1 ..< n-1: fan.triangles[fan.count]=Triangle(a:0,b:k,c:k+1); inc fan.count
  for a in 0 ..< n: fan.edges=fan.edges or edgeBit(a,(a+1) mod n)
  for k in 2 ..< n-1: fan.edges=fan.edges or edgeBit(0,k)
  var currentIndex = -1
  for i in 0 ..< total:
    if all[i].edges==fan.edges: currentIndex=i; break
  if currentIndex<0: return -1
  var current=all[currentIndex]
  var currentMetrics=evaluate(p,n,current)
  for step in 0 ..< MaxAll:
    var changed=false
    for ti in 0 ..< current.count:
      if changed: break
      let t=current.triangles[ti]
      var sides: array[3,int64]
      let score=triangleScore(p,t,sides)
      if compare(score,currentMetrics.maximum)!=0 or score.num==0: continue
      var largest=0
      if sides[1]>sides[largest]: largest=1
      if sides[2]>sides[largest]: largest=2
      let vertices=[t.a,t.b,t.c]
      for anchorPosition in 0 ..< 3:
        if changed: break
        if sides[anchorPosition]!=sides[largest]: continue
        let q=vertices[anchorPosition]
        var opposite: array[2,int]
        var used=0
        for pos in 0 ..< 3:
          if pos!=anchorPosition: opposite[used]=vertices[pos]; inc used
        for s in 0 ..< n:
          if changed: break
          let added=edgeBit(q,s)
          if s==q or (current.edges and added)!=0 or not properCross(p,q,s,opposite[0],opposite[1]): continue
          var retained=current.edges
          for u in 0 ..< n:
            for v in u+1 ..< n:
              let bit=edgeBit(u,v)
              if (retained and bit)!=0 and properCross(p,q,s,u,v): retained=retained and not bit
          var selected = -1
          var selectedMetrics=Metrics(maximum:Fraction(num:0,den:1),worst:0)
          for ci in 0 ..< total:
            if (all[ci].edges and added)==0 or (all[ci].edges and retained)!=retained: continue
            let candidate=evaluate(p,n,all[ci])
            if not improves(candidate,currentMetrics): continue
            if selected<0 or preferable(candidate,selectedMetrics):
              selected=ci
              selectedMetrics=candidate
          if selected>=0:
            current=all[selected]
            currentMetrics=selectedMetrics
            changed=true
    if not changed: break
  rankScore(p,n,currentMetrics.maximum)

proc convex_polygon_minimax_eccentricity_edge_insertion*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "convex_polygon_minimax_eccentricity_edge_insertion".} =
  if input.isNil or length<1 or length>csize_t(MaxLength): return -1
  if input[0]<MinN or input[0]>MaxN: return -1
  let n=int(input[0])
  if int(length)!=1+2*n: return -1
  var points: array[MaxN,Point]
  for i in 0 ..< n:
    points[i]=Point(x:input[1+2*i],y:input[2+2*i])
    if points[i].x < -4 or points[i].x>4 or points[i].y < -4 or points[i].y>4: return -1
    for j in 0 ..< i:
      if points[i].x==points[j].x and points[i].y==points[j].y: return -1
  var area2=0'i64
  for i in 0 ..< n:
    let next=(i+1) mod n
    area2+=points[i].x*points[next].y-points[i].y*points[next].x
  if area2==0: return -1
  let direction=if area2>0: 1'i64 else: -1'i64
  for a in 0 ..< n:
    for b in a+1 ..< n:
      for c in b+1 ..< n:
        if orient(points[a],points[b],points[c])==0: return -1
  for edge in 0 ..< n:
    let next=(edge+1) mod n
    for vertex in 0 ..< n:
      if vertex!=edge and vertex!=next and direction*orient(points[edge],points[next],points[vertex])<=0: return -1
  solve(points,n)
