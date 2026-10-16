module fft_bluestein
import math
fn fft(mut r []f64, mut im []f64, n int, inverse bool) {
 mut j:=0
 for i in 1..n {mut bit:=n>>1;for (j&bit)!=0 {j^=bit;bit>>=1};j^=bit;if i<j {r[i],r[j]=r[j],r[i];im[i],im[j]=im[j],im[i]}}
 mut len:=2
 for len<=n {a:=(if inverse {1.0}else{-1.0})*2.0*math.pi/f64(len);cr:=math.cos(a);ci:=math.sin(a);mut s:=0
  for s<n {mut wr:=1.0;mut wi:=0.0;for k in 0..len/2 {u:=s+k;v:=u+len/2;pr:=wr*r[v]-wi*im[v];pi:=wr*im[v]+wi*r[v];ur:=r[u];ui:=im[u];r[u]=ur+pr;im[u]=ui+pi;r[v]=ur-pr;im[v]=ui-pi;nr:=wr*cr-wi*ci;wi=wr*ci+wi*cr;wr=nr};s+=len};len*=2
 }
 if inverse {for i in 0..n {r[i]/=f64(n);im[i]/=f64(n)}}
}
fn quant(x f64)i64 {z:=x*1_000_000.0;if z>=0{return i64(z+0.5)};return i64(z-0.5)}
fn store(mut o &u8,p int,x i64){bits:=u64(x);for b in 0..8{unsafe{o[p+b]=u8((bits>>(b*8))&255)}}}
@[export: 'fft_bluestein']
pub fn fft_bluestein(v &i64,n usize,out &u8,cap usize)i64 {
 if isnil(v)||n<2||n>9{return -1};unsafe{
 m:=v[0];if m<1||m>8||n!=usize(m)+1{return -1};for i in 0..int(m){if v[i+1]< -8||v[i+1]>8{return -1}}
 mut z:=1;need:=int(3*m-2);for z<need{z*=2};bytes:=int(m*16);if isnil(out)||cap<bytes{return -2}
 mut ar:=[]f64{len:32,init:0.0};mut ai:=[]f64{len:32,init:0.0};mut br:=[]f64{len:32,init:0.0};mut bi:=[]f64{len:32,init:0.0}
 for j in 0..int(m){x:=-math.pi*f64(j*j)/f64(m);ar[j]=f64(v[j+1])*math.cos(x);ai[j]=f64(v[j+1])*math.sin(x)}
 for k in -(int(m)-1)..int(m){x:=math.pi*f64(k*k)/f64(m);ix:=k+int(m)-1;br[ix]=math.cos(x);bi[ix]=math.sin(x)}
 fft(mut ar,mut ai,z,false);fft(mut br,mut bi,z,false);for i in 0..z{x:=ar[i]*br[i]-ai[i]*bi[i];ai[i]=ar[i]*bi[i]+ai[i]*br[i];ar[i]=x};fft(mut ar,mut ai,z,true)
 for k in 0..int(m){x:=-math.pi*f64(k*k)/f64(m);cr:=math.cos(x);ci:=math.sin(x);re:=ar[k+int(m)-1]*cr-ai[k+int(m)-1]*ci;im:=ar[k+int(m)-1]*ci+ai[k+int(m)-1]*cr;store(mut out,16*k,quant(re));store(mut out,16*k+8,quant(im))};return i64(bytes)
 }
}
