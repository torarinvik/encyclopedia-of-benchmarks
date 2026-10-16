package generalized_esd
import "core:c"
import "core:math"
CRITICAL : [9]f64 = {0,0,0,1.1543048513440384,1.48125,1.715037312343363,1.887145117783933,2.0199685076795957,2.126645087195462}
@(export)
generalized_esd :: proc "c" (v: [^]i64, length: c.size_t) -> i64 {
 if v==nil||length<5 do return -1
 n:=v[0];limit:=v[1];if n<3||n>8||limit<1||limit>3||limit>n-2||length!=c.size_t(n)+2 do return -1
 x:[8]f64;idx:[8]int
 for i:=0;i<int(n);i+=1{if v[i+2]<-10000||v[i+2]>10000 do return -1;x[i]=f64(v[i+2]);idx[i]=i}
 remaining:=int(n);accepted:=0;removed:[3]int
 for step:=1;step<=int(limit);step+=1{mean:f64=0;for i:=0;i<remaining;i+=1{mean+=x[i]};mean/=f64(remaining);ss:f64=0;for i:=0;i<remaining;i+=1{d:=x[i]-mean;ss+=d*d};sd:=math.sqrt(ss/f64(remaining-1));if sd==0 do break;worst:=0;largest:f64=-1;for i:=0;i<remaining;i+=1{d:=math.abs(x[i]-mean);if d>largest{largest=d;worst=i}};removed[step-1]=idx[worst];if largest/sd>CRITICAL[remaining] do accepted=step;remaining-=1;x[worst]=x[remaining];idx[worst]=idx[remaining]}
 mask:i64=0;for i:=0;i<accepted;i+=1{mask|=i64(1)<<u64(removed[i])};return mask
}
