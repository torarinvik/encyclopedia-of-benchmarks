package wire_sizing
import "core:c"
import "core:math"
N :: 6
FIELDS :: 7
MAX_INPUT :: 17
abs_f :: proc(x:f64)->f64{if x<0{return -x};return x}
put_i64 :: proc(out:[^]u8,at:int,value:i64){bits:=u64(value);for i:=0;i<8;i+=1{out[at+i]=u8(bits&255);bits>>=8}}
@(export)
wire_sizing :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<7||length>MAX_INPUT { return -1 };n64:=input[0];if n64<1||n64>N { return -1 };n:=int(n64);l,rd,cl,r0:=input[1],input[2],input[3],input[4];if l<1||l>1000||rd<1||rd>1000||cl<1||cl>1000||r0<1||r0>1000||length!=c.size_t(5+2*n) { return -1 }
 h:[N]i64;c:[N]i64;for i:=0;i<n;i+=1{h[i]=input[5+i];c[i]=input[5+n+i];if h[i]<1||h[i]>32||c[i]<1||c[i]>1000||(i>0&&h[i]>=h[i-1])||(i>0&&c[i]>=c[i-1]){return -1}}
 phi:[N][N]f64;rho:[N]f64;for i:=0;i<n;i+=1{rho[i]=f64(rd)*f64(c[i])+f64(cl)*f64(r0)/f64(h[i]);for j:=0;j<n;j+=1{lo,hi:=i,j;if j<i{lo,hi=j,i};phi[i][j]=f64(r0)*f64(c[hi])/f64(h[lo])}}
 best:=1.0e300;best_l:[N]f64;found:=false;limit:=u32(1)<<u32(n)
 for mask:=u32(1);mask<limit;mask+=1{ids:[N]int;k:=0;for i:=0;i<n;i+=1{if mask&(u32(1)<<u32(i))!=0{ids[k]=i;k+=1}};a:[N+1][N+2]f64;for r:=0;r<k;r+=1{for q:=0;q<k;q+=1{a[r][q]=phi[ids[r]][ids[q]]};a[r][k]=1;a[r][k+1]=-rho[ids[r]]};for q:=0;q<k;q+=1{a[k][q]=1};a[k][k+1]=f64(l)
  ok:=true;for col:=0;col<=k;col+=1{pivot:=col;for r:=col+1;r<=k;r+=1{if abs_f(a[r][col])>abs_f(a[pivot][col]){pivot=r}};if abs_f(a[pivot][col])<1.0e-12{ok=false;break};if pivot!=col{for q:=col;q<=k+1;q+=1{tmp:=a[col][q];a[col][q]=a[pivot][q];a[pivot][q]=tmp}};div:=a[col][col];for q:=col;q<=k+1;q+=1{a[col][q]/=div};for r:=0;r<=k;r+=1{if r!=col{factor:=a[r][col];for q:=col;q<=k+1;q+=1{a[r][q]-=factor*a[col][q]}}}}
  if !ok{continue};x:[N]f64;for r:=0;r<k;r+=1{x[ids[r]]=a[r][k+1]};lambda:=a[k][k+1];sum:=0.0;for i:=0;i<n;i+=1{if x[i] < -1.0e-8{ok=false};sum+=x[i];g:=rho[i]+lambda;for j:=0;j<n;j+=1{g+=phi[i][j]*x[j]};if mask&(u32(1)<<u32(i))==0&&g < -1.0e-7{ok=false}};if abs_f(sum-f64(l))>1.0e-7{ok=false};if !ok{continue}
  objective:=f64(rd*cl);for i:=0;i<n;i+=1{objective+=rho[i]*x[i];for j:=0;j<n;j+=1{objective+=0.5*x[i]*phi[i][j]*x[j]}};if !found||objective<best-1.0e-7{found=true;best=objective;best_l=x}
 }
 if !found { return -1 };fields:[FIELDS]i64;fields[0]=i64(math.floor_f64(best*1.0e6+0.5));for i:=0;i<n;i+=1{q:=best_l[i];if q<0{q=0};fields[i+1]=i64(math.floor_f64(q*1.0e6+0.5))};bytes:=8*(n+1);if output==nil||capacity<c.size_t(bytes){return -2};stage:[8*FIELDS]u8;for i:=0;i<n+1;i+=1{put_i64(&stage[0],8*i,fields[i])};for i:=0;i<bytes;i+=1{output[i]=stage[i]};return i64(bytes)
}
