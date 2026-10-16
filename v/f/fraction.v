module main
import math
@[export: 'fraction']
pub fn fraction(v &i64,n usize,o &u8,cap usize)i64{
 if isnil(v)||n!=4{return -1}
 a:=unsafe{v[0]};d:=unsafe{v[1]};b:=unsafe{v[2]};e:=unsafe{v[3]}
 if a < -10000||a>10000||b < -10000||b>10000||d < -1000||d>1000||e < -1000||e>1000||d==0||e==0{return -1}
 if isnil(o)||cap<16{return -2}
 mut x:=i64(math.abs(d));mut y:=i64(math.abs(e));for y!=0{r:=x%y;x=y;y=r}
 mut num:=(e/x)*a+(d/x)*b;mut den:=(d/x)*e
 mut p:=i64(math.abs(num));mut q:=i64(math.abs(den));for q!=0{r:=p%q;p=q;q=r}
 num/=p;den/=p;if den<0{num = -num;den = -den}
 put_i64(mut o,0,num);put_i64(mut o,8,den);return 16
}
fn put_i64(mut o &u8,p int,x i64){bits:=u64(x);for k in 0..8{unsafe{o[p+k]=u8(bits>>(k*8))}}}
