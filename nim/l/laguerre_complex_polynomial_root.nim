import std/[math, options]

type C = tuple[re, im: float64]
proc add(a,b:C):C=(a.re+b.re,a.im+b.im)
proc sub(a,b:C):C=(a.re-b.re,a.im-b.im)
proc mul(a,b:C):C=(a.re*b.re-a.im*b.im,a.re*b.im+a.im*b.re)
proc divc(a,b:C):C=
  let d=b.re*b.re+b.im*b.im
  ((a.re*b.re+a.im*b.im)/d,(a.im*b.re-a.re*b.im)/d)
proc mag(a:C):float64=sqrt(a.re*a.re+a.im*a.im)
proc finite(x:float64):bool=x==x and x<=1.0e308 and x>= -1.0e308
proc finite(a:C):bool=finite(a.re) and finite(a.im)
proc sqrtc(a:C):C=
  let m=mag(a)
  let re=sqrt(max(0.0,(m+a.re)*0.5))
  var im=sqrt(max(0.0,(m-a.re)*0.5))
  if a.im<0.0: im = -im
  (re,im)
proc integerField(x:float64,lo,hi:int64):int64=
  if not finite(x) or x<float64(lo) or x>float64(hi) or x!=floor(x): return low(int64)
  int64(x)
proc evaluate(a:array[7,float64],n:int,z:C):(C,C,C,float64)=
  var p:C=(a[n],0.0);var dp:C=(0.0,0.0);var ddp:C=(0.0,0.0)
  for k in countdown(n-1,0):
    ddp=add(mul(ddp,z),(2.0*dp.re,2.0*dp.im))
    dp=add(mul(dp,z),p)
    p=add(mul(p,z),(a[k],0.0))
  let radius=mag(z);var scale=abs(a[n])
  for k in countdown(n-1,0): scale=scale*radius+abs(a[k])
  (p,dp,ddp,scale)
proc solve(a:array[7,float64],n:int,start:C,tolerance:float64,iterations:int):Option[C]=
  var z=start
  for step in 0..iterations:
    if not finite(z): return none(C)
    let (p,dp,ddp,scale)=evaluate(a,n,z)
    if not finite(p) or not finite(dp) or not finite(ddp) or not finite(scale): return none(C)
    if mag(p)<=tolerance*max(1.0,scale): return some(z)
    if step==iterations or (p.re==0.0 and p.im==0.0): return none(C)
    let g=divc(dp,p)
    let h=sub(mul(g,g),divc(ddp,p))
    let rad=mul((float64(n-1),0.0),sub(mul((float64(n),0.0),h),mul(g,g)))
    if not finite(g) or not finite(h) or not finite(rad): return none(C)
    let root=sqrtc(rad);let plus=add(g,root);let minus=sub(g,root)
    let denominator=if mag(plus)>=mag(minus):plus else:minus
    let dm=mag(denominator)
    if dm==0.0 or not finite(dm): return none(C)
    let correction=divc((float64(n),0.0),denominator)
    if not finite(correction): return none(C)
    z=sub(z,correction)
  none(C)

proc laguerre_complex_polynomial_root*(input:ptr UncheckedArray[float64],length:csize_t,
    output:ptr UncheckedArray[float64],capacity:csize_t):int64 {.cdecl,exportc:"laguerre_complex_polynomial_root".}=
  if input==nil or length<1 or length>13:return -1
  let degree=integerField(input[0],2,6)
  if degree==low(int64):return -1
  let n=int(degree)
  if length!=csize_t(n+6):return -1
  var a:array[7,float64]
  for i in 0..n:
    let value=integerField(input[1+i],-16,16)
    if value==low(int64):return -1
    a[i]=float64(value)
  if a[n]==0.0:return -1
  let re=integerField(input[n+2],-4000,4000);let im=integerField(input[n+3],-4000,4000)
  let tol=integerField(input[n+4],1,1000);let iterations=integerField(input[n+5],8,128)
  if re==low(int64) or im==low(int64) or tol==low(int64) or iterations==low(int64):return -1
  if output==nil or capacity<2:return -2
  let start:C=(float64(re)/1000.0,float64(im)/1000.0)
  let root=solve(a,n,start,float64(tol)/1_000_000.0,int(iterations))
  if root.isNone:return -3
  output[0]=root.get().re;output[1]=root.get().im;2
