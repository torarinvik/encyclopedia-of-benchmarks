type Point = tuple[x: int64, y: int64]

proc rplFloorDiv(a, b: int64): int64 =
  let q = a div b
  let r = a mod b
  q - (if r < 0: 1'i64 else: 0'i64)

proc rplCeilDiv(a, b: int64): int64 = -rplFloorDiv(-a, b)

proc rplFloorSum(n0, m0, a0, b0: int64): int64 =
  let aq = rplFloorDiv(a0, m0)
  let bq = rplFloorDiv(b0, m0)
  var answer = aq*n0*(n0-1) div 2 + bq*n0
  var a = a0-aq*m0
  var b = b0-bq*m0
  var n = n0
  var m = m0
  while true:
    if a >= m:
      answer += (n-1)*n*(a div m) div 2
      a = a mod m
    if b >= m:
      answer += n*(b div m)
      b = b mod m
    let top = a*n+b
    if top < m: return answer
    n = top div m
    b = top mod m
    swap(m, a)

proc rplEdgeChunk(scale, ax, ay, dx, dy, start, columns: int64): int64 =
  if columns <= 0: return 0
  var aa = dy*scale
  var bb = ay*dx-dy*ax
  var den = scale*dx
  if den < 0:
    aa = -aa
    bb = -bb
    den = -den
  let base = aa*start+bb
  if dx > 0: return -rplFloorSum(columns,den,aa,base)
  -rplFloorSum(columns,den,-aa,-base)-columns

proc rplInside(xs, ys: array[8,int64], n: int, scale, x, y: int64): bool =
  let px=x*scale
  let py=y*scale
  var inside=false
  for i in 0 ..< n:
    let j=(i+1) mod n
    let cross=(xs[j]-xs[i])*(py-ys[i])-(ys[j]-ys[i])*(px-xs[i])
    if cross==0 and px>=min(xs[i],xs[j]) and px<=max(xs[i],xs[j]) and py>=min(ys[i],ys[j]) and py<=max(ys[i],ys[j]):
      return false
    if (ys[i]>py)!=(ys[j]>py):
      let dy=ys[j]-ys[i]
      let dx=xs[j]-xs[i]
      let left=xs[i]*dy+(py-ys[i])*dx
      let right=px*dy
      if (dy>0 and left>right) or (dy<0 and left<right): inside=not inside
  inside

proc rational_polygon_lattice_points*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "rational_polygon_lattice_points".} =
  if input.isNil or length < csize_t(2) or length > csize_t(19): return -1
  let scale = input[0]
  let nr = input[1]
  if scale < 2 or scale > 8 or nr < 3 or nr > 8 or length != csize_t(2+2*nr): return -1
  let n = int(nr)
  var xs: array[8, int64]
  var ys: array[8, int64]
  var fractional = false
  for i in 0 ..< n:
    xs[i] = input[2+2*i]
    ys[i] = input[3+2*i]
    if xs[i] < -32 or xs[i] > 32 or ys[i] < -32 or ys[i] > 32: return -1
    if xs[i] < -4*scale or xs[i] > 4*scale or ys[i] < -4*scale or ys[i] > 4*scale: return -1
    if xs[i] mod scale != 0 or ys[i] mod scale != 0: fractional = true
    for j in 0 ..< i:
      if xs[i] == xs[j] and ys[i] == ys[j]: return -1
  if not fractional: return -1
  var area2 = 0'i64
  for i in 0 ..< n:
    let j = (i+1) mod n
    area2 += xs[i]*ys[j]-ys[i]*xs[j]
  if area2 == 0: return -1
  let orientation = if area2 > 0: 1'i64 else: -1'i64
  for i in 0 ..< n:
    let next = (i+1) mod n
    for j in 0 ..< n:
      if j == i or j == next: continue
      let cross = (xs[next]-xs[i])*(ys[j]-ys[i])-(ys[next]-ys[i])*(xs[j]-xs[i])
      if cross*orientation <= 0: return -1
  var signedCount = 0'i64
  for i in 0 ..< n:
    let j = (i+1) mod n
    let dx = xs[j]-xs[i]
    let dy = ys[j]-ys[i]
    if dx == 0: continue
    let lo = min(xs[i], xs[j])
    let hi = max(xs[i], xs[j])
    let start = rplCeilDiv(lo,scale)
    let stop = rplCeilDiv(hi,scale)
    var cursor=start
    for col in start ..< stop:
      var event=false
      for k in 0 ..< n:
        if xs[k] == col*scale: event=true
      if event:
        signedCount += rplEdgeChunk(scale,xs[i],ys[i],dx,dy,cursor,col-cursor)
        cursor=col+1
    signedCount += rplEdgeChunk(scale,xs[i],ys[i],dx,dy,cursor,stop-cursor)
  for i in 0 ..< n:
    if xs[i] mod scale != 0: continue
    var first=true
    for j in 0 ..< i:
      if xs[j] == xs[i]: first=false
    if not first: continue
    let x=xs[i] div scale
    var count=0'i64
    for y in -4'i64 .. 4'i64:
      if rplInside(xs,ys,n,scale,x,y): inc count
    signedCount += orientation*count
  let result = signedCount*orientation
  if result < 0: return -1
  result
