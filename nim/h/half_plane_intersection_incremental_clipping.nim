## Independently authored draft; not compiled or run.
type
  Line = object
    a,b,c: int64
  Vertex = object
    x,y,den: int64
    incoming: int

proc gcd64(a0,b0: int64): int64 =
  var a = abs(a0); var b = abs(b0)
  while b != 0:
    let r = a mod b
    a = b; b = r
  a
proc intersection(a,b: Line, p: var Vertex): bool =
  var den = a.a*b.b-b.a*a.b
  if den == 0: return false
  var x = a.c*b.b-a.b*b.c
  var y = a.a*b.c-a.c*b.a
  if den < 0: den = -den; x = -x; y = -y
  let g = gcd64(gcd64(x,y),den)
  p = Vertex(x:x div g,y:y div g,den:den div g,incoming:0)
  true
proc side(l: Line, p: Vertex): int64 = l.a*p.x+l.b*p.y-l.c*p.den
proc same(a,b: Vertex): bool = a.x*b.den == b.x*a.den and a.y*b.den == b.y*a.den
proc turn(a,b,c: Vertex): int64 =
  let dx1=b.x*a.den-a.x*b.den; let dy1=b.y*a.den-a.y*b.den
  let dx2=c.x*b.den-b.x*c.den; let dy2=c.y*b.den-b.y*c.den
  dx1*dy2-dy1*dx2
proc append(outValues: var array[32,Vertex], used: var int, p: Vertex) =
  if used == 0 or not same(outValues[used-1],p):
    outValues[used]=p
    inc used
proc put(output: ptr UncheckedArray[uint8], offset: var int, value: int64) =
  let bits=cast[uint64](value)
  for i in 0 ..< 8:
    output[offset]=uint8((bits shr (8*i)) and 255)
    inc offset

proc half_plane_intersection_incremental_clipping*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "half_plane_intersection_incremental_clipping".} =
  if input == nil or length < 1 or length > 38: return -1
  if input[0] < 0 or input[0] > 12: return -1
  let n=int(input[0])
  if length != csize_t(1+3*n): return -1
  var lines: array[16,Line]
  lines[0]=Line(a: -1,b:0,c:256); lines[1]=Line(a:0,b: -1,c:256)
  lines[2]=Line(a:1,b:0,c:256); lines[3]=Line(a:0,b:1,c:256)
  for i in 0 ..< n:
    let a=input[1+3*i]; let b=input[2+3*i]; let c=input[3+3*i]
    if a < -16 or a > 16 or b < -16 or b > 16 or c < -128 or c > 128 or (a==0 and b==0) or gcd64(a,b)!=1: return -1
    lines[4+i]=Line(a:a,b:b,c:c)
  var polygon: array[32,Vertex]
  polygon[0]=Vertex(x: -256,y: -256,den:1,incoming:0)
  polygon[1]=Vertex(x:256,y: -256,den:1,incoming:1)
  polygon[2]=Vertex(x:256,y:256,den:1,incoming:2)
  polygon[3]=Vertex(x: -256,y:256,den:1,incoming:3)
  var count=4
  for line in 4 ..< 4+n:
    if count < 3: break
    var next: array[32,Vertex]
    var used=0
    for i in 0 ..< count:
      let s=polygon[(i+count-1) mod count]
      let e=polygon[i]
      let sIn=side(lines[line],s)<=0
      let eIn=side(lines[line],e)<=0
      if sIn != eIn:
        var crossing: Vertex
        if not intersection(lines[e.incoming],lines[line],crossing): return -1
        crossing.incoming = (if sIn: e.incoming else: line)
        append(next,used,crossing)
      if eIn: append(next,used,e)
    if used > 1 and same(next[0],next[used-1]):
      next[0].incoming=next[used-1].incoming
      dec used
    count=used
    polygon=next
    var noncollinear=false
    if count >= 3:
      for i in 0 ..< count:
        if turn(polygon[i],polygon[(i+1) mod count],polygon[(i+2) mod count]) != 0: noncollinear=true
    if not noncollinear: count=0
  var changed=true
  while changed and count>=3:
    changed=false
    for i in 0 ..< count:
      if turn(polygon[(i+count-1) mod count],polygon[i],polygon[(i+1) mod count])==0:
        for j in i ..< count-1: polygon[j]=polygon[j+1]
        dec count
        changed=true
        break
  if count<3: count=0
  var first=0
  for i in 1 ..< count:
    let yi=polygon[i].y*polygon[first].den
    let yf=polygon[first].y*polygon[i].den
    if yi<yf or (yi==yf and polygon[i].x*polygon[first].den<polygon[first].x*polygon[i].den): first=i
  let needed=(1+4*count)*8
  if output == nil or capacity < csize_t(needed): return -2
  var offset=0
  put(output,offset,int64(count))
  for i in 0 ..< count:
    let p=polygon[(first+i) mod count]
    let gx=gcd64(p.x,p.den); let gy=gcd64(p.y,p.den)
    put(output,offset,p.x div gx); put(output,offset,p.den div gx)
    put(output,offset,p.y div gy); put(output,offset,p.den div gy)
  int64(needed)
