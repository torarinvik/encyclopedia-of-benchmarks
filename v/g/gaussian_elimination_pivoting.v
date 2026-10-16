module main
import math
fn put_f64(out &u8,at i64,x f64){mut bits:=math.bits_from_f64(x);for k in 0..8{unsafe{out[at+k]=u8(bits&255)};bits>>=8}}
fn absf(x f64)f64{return if x<0{-x}else{x}}
@[export: 'gaussian_elimination_pivoting']
pub fn gaussian_elimination_pivoting(v &i64,n usize,out &u8,cap usize)i64{if isnil(v)||n<1||n>21{return -1};d:=unsafe{v[0]};if d<2||d>4||n!=usize(1+d*(d+1)){return -1};mut a:=[][]f64{};for i in 0..d{mut row:=[]f64{len:int(d+1)};for j in 0..d+1{z:=unsafe{v[1+i*(d+1)+j]};if z < -10000||z>10000{return -1};row[j]=f64(z)/1000};a<<row};bytes:=usize(d*8);for col in 0..d{for i in col..d{if absf(a[i][col])>absf(a[col][col]){tmp:=a[col].clone();a[col]=a[i].clone();a[i]=tmp}};if absf(a[col][col])<1e-8{return -1};if col!=0{prior:=col-1;for i in col..d{f:=a[i][prior]/a[prior][prior];for j in 0..d+1{a[i][j]-=f*a[prior][j]}}}};mut x:=[]f64{len:int(d)};for col in 0..d{x[d-1-col]=a[d-1-col][d]/a[d-1-col][d-1-col];for row in 0..d-1-col{a[row][d]-=a[row][d-1-col]*x[d-1-col]}};if isnil(out)||cap<bytes{return -2};for i in 0..d{put_f64(out,i*8,x[i])};return i64(bytes)}
