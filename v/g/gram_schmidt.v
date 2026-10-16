module main
import math
fn put_f64(out &u8,at i64,x f64){u:=math.bits_from_f64(x);for i in 0..8{unsafe{out[at+i]=u8(u>>(8*i))}}}
@[export: 'gram_schmidt']
pub fn gram_schmidt(v &i64,n usize,out &u8,cap usize)i64{if isnil(v)||n<2||n>18{return -1};r:=unsafe{v[0]};d:=unsafe{v[1]};if r<1||r>4||d<r||d>4||n!=usize(2+r*d){return -1};mut a:=[][]f64{};mut q:=[][]f64{};for i in 0..r{mut row:=[]f64{len:int(d)};for j in 0..d{z:=unsafe{v[2+i*d+j]};if z < -1000||z>1000||(j<i&&z!=0)||(j==i&&(z<100||z>1000)){return -1};row[j]=f64(z)/1000};a<<row;q<<[]f64{len:int(d)}};bytes:=usize(r*d*8);if isnil(out)||cap<bytes{return -2};for k in 0..r{mut p:=[4]f64{};for i in 0..k{mut dot:=f64(0);mut norm:=f64(0);for j in 0..d{dot+=a[k][j]*q[i][j];norm+=q[i][j]*q[i][j]};f:=dot/norm;for j in 0..d{p[j]+=q[i][j]*f}};for j in 0..d{q[k][j]=a[k][j]-p[j]}};for i in 0..r{for j in 0..d{put_f64(out,(i*d+j)*8,q[i][j])}};return i64(bytes)}
