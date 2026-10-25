module embench_aha_mont64
fn wide(a u64,b u64)(u64,u64){mask:=u64(0xffffffff);a0:=a&mask;a1:=a>>32;b0:=b&mask;b1:=b>>32;p00:=a0*b0;p01:=a0*b1;p10:=a1*b0;p11:=a1*b1;mut lo:=p00;mut old:=lo;lo+=p01<<32;mut hi:=p11+(p01>>32);if lo<old{hi++};old=lo;lo+=p10<<32;hi+=p10>>32;if lo<old{hi++};return hi,lo}
fn mont(a u64,b u64,m u64,np u64)u64{thi,tlo:=wide(a,b);uh,ul:=wide(tlo*np,m);lo:=tlo+ul;mut hi:=thi+uh;if lo<tlo{hi++};ov:=hi<thi||(hi==thi&&lo<tlo);if ov||hi>=m{return hi-m};return hi}
fn nprime(m u64)u64{mut x:=u64(1);for _ in 0..6{x*=2-m*x};return 0-x}
@[export:'embench_aha_mont64']
pub fn embench_aha_mont64(values &i64,length usize)i64{unsafe{if values==nil||length!=3{return -1};if values[0]<0||values[1]<0||values[2]<3||(values[2]&1)==0{return -1};a:=u64(values[0]);b:=u64(values[1]);m:=u64(values[2]);if a>=m||b>=m{return -1};return i64(mont(a,b,m,nprime(m)))}}
