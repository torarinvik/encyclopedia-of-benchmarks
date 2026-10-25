package embench_aha_mont64
import "core:c"
wide :: proc(a,b:u64)->(u64,u64){mask:=u64(0xffff_ffff);a0,a1,b0,b1:=a&mask,a>>32,b&mask,b>>32;p00,p01,p10,p11:=a0*b0,a0*b1,a1*b0,a1*b1;lo:=p00;old:=lo;lo+=p01<<32;hi:=p11+(p01>>32);if lo<old{hi+=1};old=lo;lo+=p10<<32;hi+=p10>>32;if lo<old{hi+=1};return hi,lo}
mont :: proc(a,b,m,np:u64)->u64{thi,tlo:=wide(a,b);uh,ul:=wide(tlo*np,m);lo:=tlo+ul;hi:=thi+uh;if lo<tlo{hi+=1};ov:=hi<thi||(hi==thi&&lo<tlo);if ov||hi>=m{return hi-m};return hi}
nprime :: proc(m:u64)->u64{x:=u64(1);for i:=0;i<6;i+=1{x*=2-m*x};return 0-x}
@(export)
embench_aha_mont64 :: proc "c" (values:[^]i64,length:c.size_t)->i64{if values==nil||length!=3 do return -1;if values[0]<0||values[1]<0||values[2]<3||(values[2]&1)==0 do return -1;a,b,m:=u64(values[0]),u64(values[1]),u64(values[2]);if a>=m||b>=m do return -1;return i64(mont(a,b,m,nprime(m)))}
