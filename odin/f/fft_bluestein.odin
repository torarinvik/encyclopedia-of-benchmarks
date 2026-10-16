package fft_bluestein
import "core:math"
fft :: proc "contextless" (r, im: ^[32]f64, n: int, inverse: bool) {
 j:=0
 for i:=1;i<n;i+=1 {bit:=n/2;for (j&bit)!=0 {j= j ~ bit;bit/=2};j= j ~ bit;if i<j {r[i],r[j]=r[j],r[i];im[i],im[j]=im[j],im[i]}}
 len:=2
 for len<=n {direction:=f64(-1);if inverse{direction=1};a:=direction*2*math.PI/f64(len);cr:=math.cos(a);ci:=math.sin(a);s:=0
  for s<n {wr,wi:=1.0,0.0;for k:=0;k<len/2;k+=1 {u:=s+k;v:=u+len/2;pr:=wr*r[v]-wi*im[v];pi:=wr*im[v]+wi*r[v];ur,ui:=r[u],im[u];r[u]=ur+pr;im[u]=ui+pi;r[v]=ur-pr;im[v]=ui-pi;nr:=wr*cr-wi*ci;wi=wr*ci+wi*cr;wr=nr};s+=len};len*=2
 }
 if inverse {for i:=0;i<n;i+=1 {r[i]/=f64(n);im[i]/=f64(n)}}
}
quant :: proc "contextless" (x:f64)->i64 {z:=x*1_000_000.0;if z>=0{return i64(math.floor(z+0.5))};return i64(math.ceil(z-0.5))}
store :: proc "contextless" (o:[^]u8,p:int,x:i64){bits:=u64(x);for b:=0;b<8;b+=1{o[p+b]=u8(bits&255);bits>>=8}}
@(export)
fft_bluestein :: proc "c" (v:[^]i64,n:uintptr,out:[^]u8,cap:uintptr)->i64 {
 if v==nil||n<2||n>9{return -1};m:=v[0];if m<1||m>8||n!=uintptr(m)+1{return -1}
 for i:=i64(0);i<m;i+=1{if v[i+1]< -8||v[i+1]>8{return -1}}
 z:=1;need:=int(3*m-2);for z<need{z*=2};bytes:=int(m*16);if out==nil||cap<uintptr(bytes){return -2}
 ar,ai,br,bi:[32]f64
 for j:=0;j<int(m);j+=1{x:=-math.PI*f64(j*j)/f64(m);ar[j]=f64(v[j+1])*math.cos(x);ai[j]=f64(v[j+1])*math.sin(x)}
 for k:=-(int(m)-1);k<=int(m)-1;k+=1{x:=math.PI*f64(k*k)/f64(m);ix:=k+int(m)-1;br[ix]=math.cos(x);bi[ix]=math.sin(x)}
 fft(&ar,&ai,z,false);fft(&br,&bi,z,false);for i:=0;i<z;i+=1{x:=ar[i]*br[i]-ai[i]*bi[i];ai[i]=ar[i]*bi[i]+ai[i]*br[i];ar[i]=x};fft(&ar,&ai,z,true)
 for k:=0;k<int(m);k+=1{x:=-math.PI*f64(k*k)/f64(m);cr:=math.cos(x);ci:=math.sin(x);re:=ar[k+int(m)-1]*cr-ai[k+int(m)-1]*ci;im:=ar[k+int(m)-1]*ci+ai[k+int(m)-1]*cr;store(out,16*k,quant(re));store(out,16*k+8,quant(im))}
 return i64(bytes)
}
