## Independently authored draft; not compiled or run.
import std/algorithm
type
  Line = object
    a,b,c,norm: int64
  Point = object
    x,y,den: int64

proc gcd64(x,y: int64): int64 =
  var a=abs(x); var b=abs(y)
  while b != 0:
    let rem=a mod b
    a=b; b=rem
  a
proc half(l: Line): int =
  if l.b > 0 or (l.b == 0 and l.a >= 0): 0 else: 1
proc compare(a,b: Line): int =
  let ha=half(a); let hb=half(b)
  if ha != hb: return cmp(ha,hb)
  let cross=a.a*b.b-a.b*b.a
  if cross > 0: -1
  elif cross < 0: 1
  else: cmp(a.c,b.c)
proc intersection(a,b: Line,p: var Point): bool =
  var d=a.a*b.b-b.a*a.b
  if d == 0: return false
  var x=a.c*b.b-a.b*b.c; var y=a.a*b.c-a.c*b.a
  if d < 0: d = -d; x = -x; y = -y
  p=Point(x:x,y:y,den:d)
  true
proc outside(l: Line,p: Point): bool = l.a*p.x+l.b*p.y > l.c*p.den
proc feasible(lines: array[16,Line], count: int, radius: int64): bool =
  var queue: array[16,Line]
  var head=0; var tail=0
  for i in 0 ..< count:
    var h=lines[i]
    h.c=h.c*32768-(radius*32768-1)*h.norm
    if tail > head and queue[tail-1].a == h.a and queue[tail-1].b == h.b:
      if h.c >= queue[tail-1].c: continue
      dec tail
    var p: Point
    while tail-head > 1 and intersection(queue[tail-2],queue[tail-1],p) and outside(h,p): dec tail
    while tail-head > 1 and intersection(queue[head],queue[head+1],p) and outside(h,p): inc head
    if tail > head and queue[tail-1].a*h.b-queue[tail-1].b*h.a == 0: return false
    queue[tail]=h; inc tail
  var p: Point
  while tail-head > 2 and intersection(queue[tail-2],queue[tail-1],p) and outside(queue[head],p): dec tail
  while tail-head > 2 and intersection(queue[head],queue[head+1],p) and outside(queue[tail-1],p): inc head
  if tail-head < 3: return false
  for i in head ..< tail:
    let j=if i+1 == tail: head else: i+1
    if not intersection(queue[i],queue[j],p): return false
  true

proc convex_polygon_integer_inradius*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "convex_polygon_integer_inradius".} =
  if input.isNil or length < 1 or length > 38: return -1
  if input[0] < 0 or input[0] > 12: return -1
  let n=int(input[0])
  if length != csize_t(1+3*n): return -1
  var lines: array[16,Line]
  for i in 0 ..< n:
    let a=input[1+3*i]; let b=input[2+3*i]; let c=input[3+3*i]
    if a < -15 or a > 15 or b < -15 or b > 15 or c < -128 or c > 128: return -1
    let squared=a*a+b*b
    var norm=0'i64
    while norm*norm < squared: inc norm
    if norm == 0 or norm*norm != squared or gcd64(a,b) != 1: return -1
    lines[i]=Line(a:a,b:b,c:c,norm:norm)
  lines[n]=Line(a:1,b:0,c:256,norm:1)
  lines[n+1]=Line(a:0,b:1,c:256,norm:1)
  lines[n+2]=Line(a: -1,b:0,c:256,norm:1)
  lines[n+3]=Line(a:0,b: -1,c:256,norm:1)
  let count=n+4
  var sorted=lines[0 ..< count]
  sorted.sort(compare)
  for i in 0 ..< count: lines[i]=sorted[i]
  if not feasible(lines,count,0): return -2
  var low=0'i64; var high=257'i64
  while high-low > 1:
    let middle=(low+high) div 2
    if feasible(lines,count,middle): low=middle else: high=middle
  low
