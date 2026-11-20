const MaxTriangles = 3
const MaxSegments = 9
const MaxEvents = 45
type
  Rat = object
    n, d: int64
  Seg = object
    x0, y0, x1, y1: int64
    id: int
  Interval = object
    lo, hi: Rat
    low, high: Seg
    lowId, highId: int
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

proc abs64(x: int64): int64 = (if x < 0: -x else: x)
proc gcd64(a0,b0:int64):int64 =
  var a=abs64(a0);var b=abs64(b0)
  while b != 0: let t=a mod b;a=b;b=t
  (if a == 0: 1 else: a)
proc rat(n0,d0:int64):Rat =
  var n=n0;var d=d0
  if d < 0: n = -n; d = -d
  let g=gcd64(n,d)
  Rat(n:n div g,d:d div g)
proc radd(a,b:Rat):Rat=rat(a.n*b.d+b.n*a.d,a.d*b.d)
proc rsub(a,b:Rat):Rat=rat(a.n*b.d-b.n*a.d,a.d*b.d)
proc rmul(a,b:Rat):Rat=rat(a.n*b.n,a.d*b.d)
proc rdiv(a,b:Rat):Rat=rat(a.n*b.d,a.d*b.n)
proc rcmp(a,b:Rat):int =
  let x=a.n*b.d;let y=b.n*a.d
  (if x<y: -1 elif x>y: 1 else: 0)
proc cross(ax,ay,bx,by:int64):int64=ax*by-ay*bx
proc orient(a,b,c:tuple[x,y:int64]):int64=cross(b.x-a.x,b.y-a.y,c.x-a.x,c.y-a.y)
proc yAt(s:Seg,x:Rat):Rat=radd(rat(s.y0,1),rmul(rat(s.y1-s.y0,s.x1-s.x0),rsub(x,rat(s.x0,1))))
proc intersect(a,b:Seg,x:var Rat):bool =
  let rx=a.x1-a.x0;let ry=a.y1-a.y0;let sx=b.x1-b.x0;let sy=b.y1-b.y0
  let den=cross(rx,ry,sx,sy)
  if den==0:return false
  let qx=b.x0-a.x0;let qy=b.y0-a.y0
  let t=rat(cross(qx,qy,sx,sy),den);let u=rat(cross(qx,qy,rx,ry),den)
  if rcmp(t,rat(0,1))<0 or rcmp(t,rat(1,1))>0 or rcmp(u,rat(0,1))<0 or rcmp(u,rat(1,1))>0:return false
  x=radd(rat(a.x0,1),rmul(t,rat(rx,1)));true
proc addEvent(events:var array[MaxEvents,Rat],n:var int,x:Rat) =
  for i in 0..<n:
    if rcmp(events[i],x)==0:return
  events[n]=x;inc n
proc integrate(area:var Rat,low,high:Seg,xl,xr:Rat) =
  let h0=rsub(yAt(high,xl),yAt(low,xl));let h1=rsub(yAt(high,xr),yAt(low,xr))
  area=radd(area,rmul(rsub(xr,xl),rdiv(radd(h0,h1),rat(2,1))))
proc lessInterval(a,b:Interval):bool =
  let c=rcmp(a.lo,b.lo)
  if c!=0:return c<0
  if a.lowId!=b.lowId:return a.lowId<b.lowId
  let h=rcmp(a.hi,b.hi)
  if h!=0:return h<0
  a.highId<b.highId

proc triangle_union_area_vertical_decomposition*(input:I64Input,length:csize_t,output:ByteOutput,capacity:csize_t):int64 {.cdecl,exportc:"triangle_union_area_vertical_decomposition".} =
  if input==nil or length<1 or length>20:return -1
  let nv=input[0]
  if nv<1 or nv>3 or int(length)!=1+6*int(nv):return -1
  let n=int(nv)
  var tri:array[MaxTriangles,array[3,tuple[x,y:int64]]]
  for t in 0..<n:
    for j in 0..<3:
      let x=input[1+6*t+2*j];let y=input[2+6*t+2*j]
      if x < -1 or x > 1 or y < -1 or y > 1:return -1
      tri[t][j]=(x,y)
    if tri[t][0]==tri[t][1] or tri[t][0]==tri[t][2] or tri[t][1]==tri[t][2] or orient(tri[t][0],tri[t][1],tri[t][2])==0:return -1
  var seg:array[MaxSegments,Seg];var ns=0
  var events:array[MaxEvents,Rat];var ne=0
  for t in 0..<n:
    for j in 0..<3:
      let a=tri[t][j];let b=tri[t][(j+1) mod 3]
      seg[ns]=Seg(x0:a.x,y0:a.y,x1:b.x,y1:b.y,id:3*t+j)
      addEvent(events,ne,rat(a.x,1));inc ns
  for i in 0..<ns:
    for j in i+1..<ns:
      var x:Rat
      if intersect(seg[i],seg[j],x):addEvent(events,ne,x)
  for i in 1..<ne:
    let v=events[i];var j=i
    while j>0 and rcmp(v,events[j-1])<0:events[j]=events[j-1];dec j
    events[j]=v
  var area=rat(0,1)
  for e in 0..<ne-1:
    let xl=events[e];let xr=events[e+1]
    if rcmp(xl,xr)>=0:continue
    let xm=rdiv(radd(xl,xr),rat(2,1))
    var iv:array[MaxTriangles,Interval];var ni=0
    for t in 0..<n:
      var crossSeg:array[3,Seg];var ys:array[3,Rat];var count=0
      for j in 0..<3:
        let s=seg[3*t+j]
        if s.x0!=s.x1 and rcmp(xm,rat(min(s.x0,s.x1),1))>0 and rcmp(xm,rat(max(s.x0,s.x1),1))<0:
          crossSeg[count]=s;ys[count]=yAt(s,xm);inc count
      if count==0:continue
      if count!=2:return -1
      let swap=rcmp(ys[0],ys[1])>0 or (rcmp(ys[0],ys[1])==0 and crossSeg[0].id>crossSeg[1].id)
      if swap:iv[ni]=Interval(lo:ys[1],hi:ys[0],low:crossSeg[1],high:crossSeg[0],lowId:crossSeg[1].id,highId:crossSeg[0].id)
      else:iv[ni]=Interval(lo:ys[0],hi:ys[1],low:crossSeg[0],high:crossSeg[1],lowId:crossSeg[0].id,highId:crossSeg[1].id)
      inc ni
    for i in 1..<ni:
      let v=iv[i];var j=i
      while j>0 and lessInterval(v,iv[j-1]):iv[j]=iv[j-1];dec j
      iv[j]=v
    var have=false;var low,high:Seg;var top=rat(0,1);var highId=0
    for i in 0..<ni:
      let v=iv[i]
      if not have:low=v.low;high=v.high;top=v.hi;highId=v.highId;have=true;continue
      if rcmp(v.lo,top)<=0:
        let c=rcmp(v.hi,top)
        if c>0 or (c==0 and v.highId<highId):high=v.high;top=v.hi;highId=v.highId
      else:integrate(area,low,high,xl,xr);low=v.low;high=v.high;top=v.hi;highId=v.highId
    if have:integrate(area,low,high,xl,xr)
  if area.n<0 or area.d<=0 or area.n>11289600 or area.d>2822400:return -1
  if output==nil or capacity<16:return -2
  for j in 0..<8:output[j]=uint8((uint64(area.n) shr (8*j)) and 255);output[8+j]=uint8((uint64(area.d) shr (8*j)) and 255)
  16
