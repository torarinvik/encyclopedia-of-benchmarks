proc md(v,m:int64):int64 = (v mod m + m) mod m
proc inverse(v0,m:int64):int64 =
  var oldR=m;var r=md(v0,m);var oldT=0'i64;var t=1'i64
  while r!=0:
    let q=oldR div r;let nr=oldR-q*r;let nt=oldT-q*t
    oldR=r;r=nr;oldT=t;t=nt
  if oldR!=1:return 0
  md(oldT,m)
type Point=object
  infinity:bool
  x,y:int64
proc inf():Point = Point(infinity:true)
proc add(u,v:Point):Point =
  if u.infinity:return v
  if v.infinity:return u
  if u.x==v.x and md(u.y+v.y,17)==0:return inf()
  var num,den:int64
  if u.x==v.x and u.y==v.y:num=md(3*u.x*u.x+2,17);den=md(2*u.y,17)
  else:num=md(v.y-u.y,17);den=md(v.x-u.x,17)
  let slope=md(num*inverse(den,17),17);let x=md(slope*slope-u.x-v.x,17)
  Point(infinity:false,x:x,y:md(slope*(u.x-x)-u.y,17))
proc mul(point0:Point,k0:int64):Point =
  var point=point0;var k=k0;var result=inf()
  while k>0:
    if (k and 1)!=0:result=add(result,point)
    k=k shr 1
    if k>0:point=add(point,point)
  result
proc onCurve(q:Point):bool = md(q.y*q.y-q.x*q.x*q.x-2*q.x-2,17)==0
proc ecdsa_signature_verification*(values:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],outputCapacity:csize_t):int64 {.cdecl,exportc:"ecdsa_signature_verification".}=
  if values.isNil or length!=11:return -1
  let p=values[0];let a=values[1];let b=values[2];let gx=values[3];let gy=values[4];let order=values[5]
  let qx=values[6];let qy=values[7];let z=values[8];let r=values[9];let s=values[10]
  if p!=17 or a!=2 or b!=2 or gx!=5 or gy!=1 or order!=19:return -1
  if md(4*a*a*a+27*b*b,p)==0 or qx<0 or qx>=p or qy<0 or qy>=p or z<0 or z>31 or r<1 or r>=order or s<1 or s>=order:return -1
  let g=Point(infinity:false,x:gx,y:gy);let q=Point(infinity:false,x:qx,y:qy)
  if not onCurve(g) or not onCurve(q) or not mul(g,order).infinity or not mul(q,order).infinity:return -1
  if output.isNil or outputCapacity<1:return -2
  let w=inverse(s,order);if w==0:return -1
  let u1=z*w mod order;let u2=r*w mod order;let check=add(mul(g,u1),mul(q,u2))
  output[0]=uint8(not check.infinity and check.x mod order==r)
  1
