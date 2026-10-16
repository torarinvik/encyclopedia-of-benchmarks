package gaussian_elimination_pivoting
import "core:c"
absf :: proc(x:f64)->f64{if x<0{return -x};return x}
put :: proc(o:[^]u8,p:int,x:f64){bits:=transmute(u64)x;for k:=0;k<8;k+=1{o[p+k]=u8(bits>>(8*k))}}
@(export)
gaussian_elimination_pivoting :: proc "c"(v:[^]i64,n:c.size_t,o:[^]u8,cap:c.size_t)->i64{if v==nil||n<1||n>21 do return -1;d:=v[0];if d<2||d>4||n!=c.size_t(1+d*(d+1)) do return -1;a:[4][5]f64{};for i:=i64(0);i<d;i+=1{for j:=i64(0);j<=d;j+=1{z:=v[1+i*(d+1)+j];if z < -10000||z>10000 do return -1;a[i][j]=f64(z)/1000}};bytes:=c.size_t(d*8);for col:=i64(0);col<d;col+=1{for i:=col;i<d;i+=1{if absf(a[i][col])>absf(a[col][col]){for j:=i64(0);j<=d;j+=1{t:=a[col][j];a[col][j]=a[i][j];a[i][j]=t}}};if absf(a[col][col])<1e-8 do return -1;if col>0{prior:=col-1;for i:=col;i<d;i+=1{f:=a[i][prior]/a[prior][prior];for j:=i64(0);j<=d;j+=1{a[i][j]-=f*a[prior][j]}}}};x:[4]f64{};for col:=d;col>0;{col-=1;x[col]=a[col][d]/a[col][col];for i:=col;i>0;{i-=1;a[i][d]-=a[i][col]*x[col]}};if o==nil||cap<bytes do return -2;for i:=i64(0);i<d;i+=1{put(o,int(i)*8,x[i])};return i64(bytes)}
