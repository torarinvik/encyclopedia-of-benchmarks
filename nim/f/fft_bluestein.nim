import math
proc fft(r, im: var array[32,float64], n: int, inverse: bool) =
  var j=0
  for i in 1..<n:
    var bit=n shr 1
    while (j and bit)!=0: j=j xor bit; bit=bit shr 1
    j=j xor bit
    if i<j: swap(r[i],r[j]);swap(im[i],im[j])
  var len=2
  while len<=n:
    let a=(if inverse:1.0 else: -1.0)*2.0*PI/float64(len)
    let cr=cos(a);let ci=sin(a)
    var s=0
    while s<n:
      var wr=1.0;var wi=0.0
      for k in 0..<(len div 2):
        let u=s+k;let v=u+len div 2
        let pr=wr*r[v]-wi*im[v];let pi=wr*im[v]+wi*r[v];let ur=r[u];let ui=im[u]
        r[u]=ur+pr;im[u]=ui+pi;r[v]=ur-pr;im[v]=ui-pi
        let nr=wr*cr-wi*ci;wi=wr*ci+wi*cr;wr=nr
      s+=len
    len*=2
  if inverse:
    for i in 0..<n:r[i]/=float64(n);im[i]/=float64(n)
proc quant(x:float64):int64 =
  let z=x*1_000_000.0
  if z>=0: int64(floor(z+0.5)) else: int64(ceil(z-0.5))
proc fft_bluestein*(v:ptr int64,n:uint64,outp:ptr uint8,cap:uint64):int64 {.cdecl,exportc.} =
  if v==nil or n<2 or n>9:return -1
  let a=cast[ptr UncheckedArray[int64]](v)
  let m=int(a[0]);if m<1 or m>8 or int(n)!=m+1:return -1
  for i in 0..<m:
    if a[i+1] < -8 or a[i+1] > 8:
      return -1
  var z=1;let need=3*m-2;while z<need:z*=2
  let bytes=m*16;if outp==nil or cap<uint64(bytes):return -2
  var ar,ai,br,bi:array[32,float64]
  for j in 0..<m:
    let x= -PI*float64(j*j)/float64(m);ar[j]=float64(a[j+1])*cos(x);ai[j]=float64(a[j+1])*sin(x)
  for k in -(m-1)..(m-1):
    let x=PI*float64(k*k)/float64(m);let ix=k+m-1;br[ix]=cos(x);bi[ix]=sin(x)
  fft(ar,ai,z,false);fft(br,bi,z,false)
  for i in 0..<z:
    let x=ar[i]*br[i]-ai[i]*bi[i]
    ai[i]=ar[i]*bi[i]+ai[i]*br[i]
    ar[i]=x
  fft(ar,ai,z,true)
  let o=cast[ptr UncheckedArray[uint8]](outp)
  for k in 0..<m:
    let x= -PI*float64(k*k)/float64(m);let cr=cos(x);let ci=sin(x)
    let re=ar[k+m-1]*cr-ai[k+m-1]*ci;let im=ar[k+m-1]*ci+ai[k+m-1]*cr
    for q in 0..1:
      let val = if q == 0: quant(re) else: quant(im)
      let bits=cast[uint64](val)
      for b in 0..<8:o[16*k+q*8+b]=uint8((bits shr (b*8)) and 255)
  int64(bytes)
