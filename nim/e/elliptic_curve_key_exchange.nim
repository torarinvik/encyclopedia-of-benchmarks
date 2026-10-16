proc md(x,p:int64):int64 = (x mod p + p) mod p
proc prime(p:int64):bool =
  if p < 2: return false
  var d=2'i64
  while d*d<=p:
    if p mod d==0:return false
    inc d
  true
proc powm(x0,n0,p:int64):int64 =
  var x=md(x0,p);var n=n0;var r=1'i64
  while n>0:
    if (n and 1)!=0:r=(r*x) mod p
    x=(x*x) mod p;n=n shr 1
  r
type Pt=object
  inf:bool
  x,y:int64
proc add(p,a:int64,u,v:Pt):Pt =
  if u.inf:return v
  if v.inf:return u
  if u.x==v.x and md(u.y+v.y,p)==0:return Pt(inf:true)
  var slope:int64
  if u.x==v.x and u.y==v.y:slope=md((3*u.x*u.x+a)*powm(2*u.y,p-2,p),p)
  else:slope=md((v.y-u.y)*powm(v.x-u.x,p-2,p),p)
  let x=md(slope*slope-u.x-v.x,p)
  Pt(inf:false,x:x,y:md(slope*(u.x-x)-u.y,p))
proc mul(p,a:int64,point:Pt,scalar0:int64):Pt =
  var q=point;var k=scalar0;var r=Pt(inf:true)
  while k>0:
    if (k and 1)!=0:r=add(p,a,r,q)
    k=k shr 1
    if k>0:q=add(p,a,q,q)
  r
proc put(o:ptr UncheckedArray[uint8],pos:int,v:int64)=
  let b=uint64(v)
  for i in 0..<8:o[pos+i]=uint8((b shr (8*i)) and 255'u64)
proc elliptic_curve_key_exchange*(values:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],outputCapacity:csize_t):int64 {.cdecl,exportc:"elliptic_curve_key_exchange".}=
  if values.isNil or length!=7:return -1
  let p=values[0];let a=values[1];let b=values[2];let x=values[3];let y=values[4];let ka=values[5];let kb=values[6]
  if p<5 or p>251 or not prime(p) or a<0 or a>=p or b<0 or b>=p or x<0 or x>=p or y<0 or y>=p or ka<1 or ka>1024 or kb<1 or kb>1024:return -1
  if md(4*a*a*a+27*b*b,p)==0 or md(y*y-x*x*x-a*x-b,p)!=0:return -1
  if outputCapacity<48 or output.isNil:return -2
  let g=Pt(inf:false,x:x,y:y);let ap=mul(p,a,g,ka);let bp=mul(p,a,g,kb);let s=mul(p,a,ap,kb);let t=mul(p,a,bp,ka)
  if s.inf!=t.inf or (not s.inf and (s.x!=t.x or s.y!=t.y)):return -1
  let q=[ap,bp,s]
  for i in 0..<3:
    put(output,i*16,if q[i].inf: -1 else: q[i].x);put(output,i*16+8,if q[i].inf: -1 else: q[i].y)
  48
