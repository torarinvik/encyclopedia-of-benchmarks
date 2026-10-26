# Clean-room bounded MAFFT Falign FFT lag profile; see package LICENSE.txt.
import std/math
const MaxN=64
const AminoCodes:array[20,int64]=[65,82,78,68,67,81,69,71,72,73,76,75,77,70,80,83,84,87,89,86]
const Polarity:array[20,float64]=[8.1,10.5,11.6,13.0,5.5,10.5,12.3,9.0,10.4,5.2,4.9,11.3,5.7,5.2,8.0,9.2,8.6,5.4,6.2,5.9]
const Volume:array[20,float64]=[31.0,124.0,56.0,54.0,55.0,85.0,83.0,3.0,96.0,111.0,111.0,119.0,105.0,132.0,32.5,32.0,61.0,170.0,136.0,84.0]
proc channel(code:int64):int =
  for q in 0..<20:
    if AminoCodes[q]==code:return q
  -1
proc fft(re,im:var array[MaxN,float64],offset,n:int,inverse:bool) =
  var j=0
  for i in 1..<n:
    var bit=n shr 1
    while (j and bit)!=0:j=j xor bit;bit=bit shr 1
    j=j xor bit
    if i<j:swap(re[offset+i],re[offset+j]);swap(im[offset+i],im[offset+j])
  var span=2
  while span<=n:
    let angle=(if inverse:1.0 else: -1.0)*2.0*PI/float64(span)
    let cr=cos(angle);let ci=sin(angle)
    var start=0
    while start<n:
      var wr=1.0;var wi=0.0
      for k in 0..<(span div 2):
        let u=offset+start+k;let v=u+span div 2
        let pr=wr*re[v]-wi*im[v];let pi=wr*im[v]+wi*re[v];let ur=re[u];let ui=im[u]
        re[u]=ur+pr;im[u]=ui+pi;re[v]=ur-pr;im[v]=ui-pi
        let nw=wr*cr-wi*ci;wi=wr*ci+wi*cr;wr=nw
      start+=span
    span*=2
  if not inverse:
    for q in 0..<n:re[offset+q]/=float64(n);im[offset+q]/=float64(n)

proc mafft_falign_fft_lag_correlation*(input:ptr UncheckedArray[float64],length:csize_t,
    output:ptr UncheckedArray[float64],capacity:csize_t):int64 {.cdecl,exportc:"mafft_falign_fft_lag_correlation".} =
  if input.isNil or length<csize_t(4) or length>csize_t(66):return -1
  for q in 0..<int(length):
    let v=input[q]
    if not v.isFinite or v!=floor(v):return -1
  if input[0]<1 or input[0]>32 or input[1]<1 or input[1]>32:return -1
  let n1=int(input[0]);let n2=int(input[1])
  if int(length)!=2+n1+n2:return -1
  for q in 2..<int(length):
    if input[q]<65.0 or input[q]>90.0 or channel(int64(input[q]))<0:return -1
  var n=1
  while n<=max(n1,n2):n*=2
  if output.isNil or capacity<csize_t(n):return -2
  var r1,r2,i1,i2:array[MaxN,float64]
  var re,im:array[MaxN,float64]
  var mp=0.0;var mv=0.0
  for ch in 0..<20:
    mp+=Polarity[ch]
    mv+=Volume[ch]
  mp/=20.0;mv/=20.0
  var vp=0.0;var vv=0.0
  for ch in 0..<20:
    let dp=Polarity[ch]-mp
    let dv=Volume[ch]-mv
    vp+=dp*dp
    vv+=dv*dv
  let sp=sqrt(vp/20.0);let sv=sqrt(vv/20.0)
  for p in 0..<n1:
    let ch=channel(int64(input[2+p]))
    r1[p]=(Polarity[ch]-mp)/sp
    i1[p]=(Volume[ch]-mv)/sv
  for p in 0..<n2:
    let ch=channel(int64(input[2+n1+p]))
    r2[p]=(Polarity[ch]-mp)/sp
    i2[p]=(Volume[ch]-mv)/sv
  fft(r1,i1,0,n,false);fft(r2,i2,0,n,false)
  for k in 0..<n:
    re[k]=r1[k]*r2[k]+i1[k]*i2[k]
    im[k]= -r1[k]*i2[k]+i1[k]*r2[k]
  fft(re,im,0,n,true)
  for q in 0..<n:output[q]=re[(n div 2+n-q) mod n]
  int64(n)
