## Independently authored draft; not compiled or run.
type
  Point = tuple[x, y: int64]
  Circle = object
    x, y, den, radius2: int64

proc distance(c: Circle, p: Point): int64 =
  let dx = p.x*c.den-c.x
  let dy = p.y*c.den-c.y
  dx*dx + dy*dy

proc pointCircle(p: Point): Circle = Circle(x:p.x, y:p.y, den:1, radius2:0)
proc pairCircle(a, b: Point): Circle =
  result = Circle(x:a.x+b.x, y:a.y+b.y, den:2, radius2:0)
  result.radius2 = distance(result, a)

proc tripleCircle(a, b, c: Point): Circle =
  var den = 2*(a.x*(b.y-c.y)+b.x*(c.y-a.y)+c.x*(a.y-b.y))
  if den == 0:
    let ab = pairCircle(a,b)
    let ac = pairCircle(a,c)
    let bc = pairCircle(b,c)
    if ab.radius2 >= ac.radius2 and ab.radius2 >= bc.radius2: return ab
    if ac.radius2 >= bc.radius2: return ac
    return bc
  let aa = a.x*a.x+a.y*a.y
  let bb = b.x*b.x+b.y*b.y
  let cc = c.x*c.x+c.y*c.y
  var x = aa*(b.y-c.y)+bb*(c.y-a.y)+cc*(a.y-b.y)
  var y = aa*(c.x-b.x)+bb*(a.x-c.x)+cc*(b.x-a.x)
  if den < 0:
    den = -den; x = -x; y = -y
  result = Circle(x:x, y:y, den:den, radius2:0)
  result.radius2 = distance(result, a)

proc minimum_enclosing_circle_incremental_boundary*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "minimum_enclosing_circle_incremental_boundary".} =
  if input == nil or length < 4 or length > 194: return -1
  if input[0] < 1 or input[0] > 64: return -1
  let n = int(input[0])
  if length != csize_t(1+3*n): return -1
  var points: array[64, Point]
  var order: array[64, int]
  var seen: array[64, bool]
  for i in 0 ..< n:
    let x = input[1+2*i]
    let y = input[2+2*i]
    if x < -100 or x > 100 or y < -100 or y > 100: return -1
    points[i] = (x,y)
  for i in 0 ..< n:
    let v = input[1+2*n+i]
    if v < 0 or v >= int64(n): return -1
    if seen[int(v)]: return -1
    seen[int(v)] = true
    order[i] = int(v)
  if output == nil or capacity < csize_t(n): return -2
  var circle = pointCircle(points[order[0]])
  for i in 1 ..< n:
    let a = points[order[i]]
    if distance(circle,a) <= circle.radius2: continue
    circle = pointCircle(a)
    for j in 0 ..< i:
      let b = points[order[j]]
      if distance(circle,b) <= circle.radius2: continue
      circle = pairCircle(a,b)
      for k in 0 ..< j:
        let c = points[order[k]]
        if distance(circle,c) > circle.radius2: circle = tripleCircle(a,b,c)
  for i in 0 ..< n:
    output[i] = uint8(ord(distance(circle,points[i]) == circle.radius2))
  int64(n)
