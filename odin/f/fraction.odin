package fraction
import "core:c"
gcd_pos :: proc(a0,b0:i64)->i64{a,b:=a0,b0;if a<0{a=-a};if b<0{b=-b};for b!=0{r:=a%b;a=b;b=r};return a}
put64 :: proc(o:[^]u8,p:int,x:i64){bits:=transmute(u64)x;for k:=0;k<8;k+=1{o[p+k]=u8(bits>>u64(k*8))}}
@(export)
fraction :: proc "c" (v:[^]i64,n:c.size_t,o:[^]u8,cap:c.size_t)->i64{if v==nil||n!=4 do return -1;n1,d1,n2,d2:=v[0],v[1],v[2],v[3];if n1 < -10000||n1>10000||n2 < -10000||n2>10000||d1 < -1000||d1>1000||d2 < -1000||d2>1000||d1==0||d2==0 do return -1;if o==nil||cap<16 do return -2;g:=gcd_pos(d1,d2);num:=(d2/g)*n1+(d1/g)*n2;den:=(d1/g)*d2;r:=gcd_pos(num,den);num/=r;den/=r;if den<0{num = -num;den = -den};put64(o,0,num);put64(o,8,den);return 16}
