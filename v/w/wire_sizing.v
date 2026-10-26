module wire_sizing
const max_n=6
const max_fields=7
const max_input=17
fn abs_f(x f64)f64{if x<0{return -x};return x}
fn put_i64(mut out &u8,at int,value i64){bits:=u64(value);for b in 0..8{unsafe{out[at+b]=u8((bits>>(8*b))&255)}}}
@[export:'wire_sizing']
pub fn wire_sizing(input &i64,length usize,mut output &u8,capacity usize)i64{unsafe{
 if input==nil||length<7||length>max_input{return -1};n64:=input[0];if n64<1||n64>max_n{return -1};n:=int(n64);l,rd,cl,r0:=input[1],input[2],input[3],input[4];if l<1||l>1000||rd<1||rd>1000||cl<1||cl>1000||r0<1||r0>1000||length!=usize(5+2*n){return -1}
 mut h:=[max_n]i64{};mut c:=[max_n]i64{};for i in 0..n{h[i]=input[5+i];c[i]=input[5+n+i];if h[i]<1||h[i]>32||c[i]<1||c[i]>1000||(i>0&&h[i]>=h[i-1])||(i>0&&c[i]>=c[i-1]){return -1}}
 mut phi:=[max_n][max_n]f64{};mut rho:=[max_n]f64{};for i in 0..n{rho[i]=f64(rd)*f64(c[i])+f64(cl)*f64(r0)/f64(h[i]);for j in 0..n{lo,hi:=i,j;if j<i{lo,hi=j,i};phi[i][j]=f64(r0)*f64(c[hi])/f64(h[lo])}}
 mut best:=1.0e300;mut best_l:=[max_n]f64{};mut found:=false;limit:=1<<n
 for mask in 1..limit{mut ids:=[max_n]int{};mut k:=0;for i in 0..n{if mask&(1<<i)!=0{ids[k]=i;k++}};mut a:=[max_n+1][max_n+2]f64{};for r in 0..k{for q in 0..k{a[r][q]=phi[ids[r]][ids[q]]};a[r][k]=1;a[r][k+1]= -rho[ids[r]]};for q in 0..k{a[k][q]=1};a[k][k+1]=f64(l)
  mut ok:=true;for col in 0..k+1{mut pivot:=col;for r in col+1..k+1{if abs_f(a[r][col])>abs_f(a[pivot][col]){pivot=r}};if abs_f(a[pivot][col])<1.0e-12{ok=false;break};if pivot!=col{for q in col..k+2{tmp:=a[col][q];a[col][q]=a[pivot][q];a[pivot][q]=tmp}};div:=a[col][col];for q in col..k+2{a[col][q]/=div};for r in 0..k+1{if r!=col{factor:=a[r][col];for q in col..k+2{a[r][q]-=factor*a[col][q]}}}}
  if !ok{continue};mut x:=[max_n]f64{};for r in 0..k{x[ids[r]]=a[r][k+1]};lambda:=a[k][k+1];mut total:=f64(0);for i in 0..n{if x[i] < -1.0e-8{ok=false};total+=x[i];mut g:=rho[i]+lambda;for j in 0..n{g+=phi[i][j]*x[j]};if mask&(1<<i)==0&&g < -1.0e-7{ok=false}};if abs_f(total-f64(l))>1.0e-7{ok=false};if !ok{continue}
  mut objective:=f64(rd*cl);for i in 0..n{objective+=rho[i]*x[i];for j in 0..n{objective+=0.5*x[i]*phi[i][j]*x[j]}};if !found||objective<best-1.0e-7{found=true;best=objective;best_l=x}
 }
 if !found{return -1};mut fields:=[max_fields]i64{};fields[0]=i64(best*1.0e6+0.5);for i in 0..n{q:=if best_l[i]<0{0.0}else{best_l[i]};fields[i+1]=i64(q*1.0e6+0.5)};bytes:=8*(n+1);if output==nil||capacity<bytes{return -2};mut staged:=[8*max_fields]u8{};for i in 0..n+1{put_i64(mut &staged[0],8*i,fields[i])};for i in 0..bytes{output[i]=staged[i]};return i64(bytes)
}}
