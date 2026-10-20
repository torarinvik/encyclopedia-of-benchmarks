import std/[math, algorithm]
const MaxSites=8
const MaxArcs=15
const MaxVertices=32
const MaxOutput=1024
const Eps=1e-10
type
  Point=object
    x,y:float64
  Arc=object
    site,prev,next:int
    active:bool
  Circle=object
    y,x:float64
    arc,left,right:int
  Rat=object
    n,d:int64
  RPoint=object
    x,y:Rat
proc rat(n0,d0:int64):Rat=
  var n=n0;var d=d0
  if d<0:n= -n;d= -d
  var a=abs(n);var b=abs(d)
  while b!=0:let t=a mod b;a=b;b=t
  let g=if a==0:1'i64 else:a
  Rat(n:n div g,d:d div g)
proc add(a,b:Rat):Rat=rat(a.n*b.d+b.n*a.d,a.d*b.d)
proc sub(a,b:Rat):Rat=rat(a.n*b.d-b.n*a.d,a.d*b.d)
proc mul(a,b:Rat):Rat=rat(a.n*b.n,a.d*b.d)
proc divr(a,b:Rat):Rat=rat(a.n*b.d,a.d*b.n)
proc cmp(a,b:Rat):int=
  let l=a.n*b.d;let r=b.n*a.d
  if l<r: -1 elif l>r: 1 else: 0
proc equal(a,b:RPoint):bool=cmp(a.x,b.x)==0 and cmp(a.y,b.y)==0
proc lessp(a,b:RPoint):bool=cmp(a.x,b.x)<0 or (cmp(a.x,b.x)==0 and cmp(a.y,b.y)<0)
proc orient(a,b,c:Point):int=
  let v=(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)
  if v>0:1 elif v<0: -1 else:0
proc breakpoint(p,q:Point,lineY:float64):float64=
  if abs(p.y-q.y)<Eps:return (p.x+q.x)*0.5
  let dp=p.y-lineY;let dq=q.y-lineY;let a=q.y-p.y
  let b= -2.0*p.x*dq+2.0*q.x*dp
  let c=(p.x*p.x+p.y*p.y-lineY*lineY)*dq-(q.x*q.x+q.y*q.y-lineY*lineY)*dp
  var disc=b*b-4.0*a*c
  if disc<0.0 and disc> -Eps:disc=0.0
  let root=sqrt(disc);let r1=(-b-root)/(2.0*a);let r2=(-b+root)/(2.0*a)
  if p.y<q.y:max(r1,r2) else:min(r1,r2)
proc circle(a,b,c:Point,sweep:float64,outp:var Circle,arc,left,right:int):bool=
  if orient(a,b,c)>=0:return false
  let aa=a.x*a.x+a.y*a.y;let bb=b.x*b.x+b.y*b.y;let cc=c.x*c.x+c.y*c.y
  let d=2.0*(a.x*(b.y-c.y)+b.x*(c.y-a.y)+c.x*(a.y-b.y))
  if abs(d)<Eps:return false
  let x=(aa*(b.y-c.y)+bb*(c.y-a.y)+cc*(a.y-b.y))/d
  let y=(aa*(c.x-b.x)+bb*(a.x-c.x)+cc*(b.x-a.x))/d
  let dx=x-a.x;let dy=y-a.y;let bottom=y-sqrt(dx*dx+dy*dy)
  if not (bottom<sweep-Eps):return false
  outp=Circle(y:bottom,x:x,arc:arc,left:left,right:right)
  true
proc distance(p:RPoint,a,b,c:int64):Rat=sub(add(mul(rat(a,1),p.x),mul(rat(b,1),p.y)),rat(c,1))
proc intersection(p,q:RPoint,dp,dq:Rat):RPoint=
  let t=divr(dp,sub(dp,dq))
  RPoint(x:add(p.x,mul(t,sub(q.x,p.x))),y:add(p.y,mul(t,sub(q.y,p.y))))
proc push(p:var array[MaxVertices,RPoint],n:var int,q:RPoint)=
  if n==0 or not equal(p[n-1],q):p[n]=q;inc n
proc clip(poly:var array[MaxVertices,RPoint],count:int,a,b,c:int64):int=
  var next:array[MaxVertices,RPoint];var n=0
  for i in 0..<count:
    let p=poly[i];let q=poly[(i+1) mod count]
    let dp=distance(p,a,b,c);let dq=distance(q,a,b,c)
    let pin=dp.n<=0;let qin=dq.n<=0
    if pin and qin:push(next,n,q)
    elif pin and not qin:push(next,n,intersection(p,q,dp,dq))
    elif not pin and qin:push(next,n,intersection(p,q,dp,dq));push(next,n,q)
  if n>1 and equal(next[0],next[n-1]):dec n
  for i in 0..<n:poly[i]=next[i]
  n
proc valid(input:ptr UncheckedArray[int64],n:int):bool=
  for i in 0..<n:
    for j in i+1..<n:
      if input[1+2*i]==input[1+2*j] and input[2+2*i]==input[2+2*j]:return false
      if input[2+2*i]==input[2+2*j]:return false
  for i in 0..<n:
    for j in i+1..<n:
      for k in j+1..<n:
        let ax=input[1+2*i];let ay=input[2+2*i];let bx=input[1+2*j];let by=input[2+2*j];let cx=input[1+2*k];let cy=input[2+2*k]
        if (bx-ax)*(cy-ay)==(by-ay)*(cx-ax):return false
  for i in 0..<n:
    for j in i+1..<n:
      for k in j+1..<n:
        for l in k+1..<n:
          let ax=input[1+2*i]-input[1+2*l];let ay=input[2+2*i]-input[2+2*l]
          let bx=input[1+2*j]-input[1+2*l];let by=input[2+2*j]-input[2+2*l]
          let cx=input[1+2*k]-input[1+2*l];let cy=input[2+2*k]-input[2+2*l]
          let aa=ax*ax+ay*ay;let bb=bx*bx+by*by;let cc=cx*cx+cy*cy
          let det=ax*(by*cc-bb*cy)-ay*(bx*cc-bb*cx)+aa*(bx*cy-by*cx)
          if det==0:return false
  true
proc put(output:ptr UncheckedArray[uint8],slot:int,value:int64)=
  let bits=cast[uint64](value)
  for i in 0..<8:output[slot*8+i]=uint8((bits shr (8*i)) and 255)
proc fortune_voronoi*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"fortune_voronoi".}=
  if input==nil or length<3:return -1
  let n64=input[0]
  if n64<1 or n64>MaxSites or int(length)!=1+2*int(n64):return -1
  let n=int(n64)
  for i in 0..<n:
    if input[1+2*i]< -8 or input[1+2*i]>8 or input[2+2*i]< -8 or input[2+2*i]>8:return -1
  if not valid(input,n):return -1
  var sites:array[MaxSites,Point];var order:array[MaxSites,int]
  for i in 0..<n:sites[i]=Point(x:float64(input[1+2*i]),y:float64(input[2+2*i]));order[i]=i
  for i in 1..<n:
    let v=order[i];var j=i
    while j>0 and sites[order[j-1]].y<sites[v].y:order[j]=order[j-1];dec j
    order[j]=v
  var arcs:array[MaxArcs,Arc];var arcCount=1;let firstInit=0;var first=firstInit
  arcs[0]=Arc(site:order[0],prev: -1,next: -1,active:true)
  var nextSite=1;var sweep=sites[order[0]].y;var adjacent:array[MaxSites,array[MaxSites,bool]]
  while nextSite<n or first>=0:
    var best:Circle;var has=false
    var b=first
    while b>=0:
      let l=arcs[b].prev;let r=arcs[b].next
      if l>=0 and r>=0:
        let si=arcs[l].site;let sj=arcs[b].site;let sk=arcs[r].site
        if si!=sj and sj!=sk and si!=sk:
          var candidate:Circle
          if circle(sites[si],sites[sj],sites[sk],sweep,candidate,b,l,r) and (not has or candidate.y>best.y+Eps or (abs(candidate.y-best.y)<=Eps and b<best.arc)):
            best=candidate;has=true
      b=arcs[b].next
    let doSite=nextSite<n and (not has or sites[order[nextSite]].y>best.y+Eps)
    if not doSite and not has:break
    if doSite:
      let site=order[nextSite];inc nextSite;sweep=sites[site].y
      var arc=first
      while arcs[arc].next>=0:
        let right=arcs[arc].next
        if sites[site].x<breakpoint(sites[arcs[arc].site],sites[arcs[right].site],sweep):break
        arc=right
      let oldNext=arcs[arc].next;let oldSite=arcs[arc].site
      if arcCount+2>MaxArcs:return -1
      let middle=arcCount;inc arcCount;arcs[middle]=Arc(site:site,prev:arc,next: -1,active:true)
      let right=arcCount;inc arcCount;arcs[right]=Arc(site:oldSite,prev:middle,next:oldNext,active:true)
      arcs[arc].next=middle;arcs[middle].next=right
      if oldNext>=0:arcs[oldNext].prev=right
      adjacent[oldSite][site]=true;adjacent[site][oldSite]=true
    else:
      let arc=best.arc;let left=best.left;let right=best.right
      if not arcs[arc].active or arcs[arc].prev!=left or arcs[arc].next!=right:return -1
      sweep=best.y;let ls=arcs[left].site;let rs=arcs[right].site
      adjacent[ls][rs]=true;adjacent[rs][ls]=true
      arcs[left].next=right;arcs[right].prev=left;arcs[arc].active=false
  var values:array[MaxOutput,int64];var used=0;values[used]=int64(n);inc used
  for i in 0..<n:
    var poly:array[MaxVertices,RPoint]
    poly[0]=RPoint(x:Rat(n: -16,d:1),y:Rat(n: -16,d:1));poly[1]=RPoint(x:Rat(n:16,d:1),y:Rat(n: -16,d:1))
    poly[2]=RPoint(x:Rat(n:16,d:1),y:Rat(n:16,d:1));poly[3]=RPoint(x:Rat(n: -16,d:1),y:Rat(n:16,d:1))
    var count=4
    for j in 0..<n:
      if adjacent[i][j]:
        let x=input[1+2*j];let y=input[2+2*j];let sx=input[1+2*i];let sy=input[2+2*i]
        count=clip(poly,count,2*(x-sx),2*(y-sy),x*x+y*y-sx*sx-sy*sy)
    if count<3 or used+2+4*count>MaxOutput:return -1
    var start=0
    for j in 1..<count:if lessp(poly[j],poly[start]):start=j
    values[used]=int64(i);inc used;values[used]=int64(count);inc used
    for j in 0..<count:
      let p=poly[(start+j) mod count]
      values[used]=p.x.n;inc used;values[used]=p.x.d;inc used;values[used]=p.y.n;inc used;values[used]=p.y.d;inc used
  let bytes=used*8
  if output==nil or int(capacity)<bytes:return -2
  for i in 0..<used:put(output,i,values[i])
  int64(bytes)
