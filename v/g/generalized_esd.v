module generalized_esd
import math
@[export: 'generalized_esd']
pub fn generalized_esd(values voidptr, length usize) i64 {
 if length<usize(5)||unsafe{values==nil}{return i64(-1)}
 mut critical := [9]f64{}
 critical[3]=1.1543048513440384;critical[4]=1.48125;critical[5]=1.715037312343363;critical[6]=1.887145117783933;critical[7]=2.0199685076795957;critical[8]=2.126645087195462
 a:=unsafe{&i64(values)};n:=unsafe{a[0]};limit:=unsafe{a[1]}
 if n<3||n>8||limit<1||limit>3||limit>n-2||length!=usize(n+2){return i64(-1)}
 mut x:=[8]f64{};mut idx:=[8]int{}
 for i in 0..int(n){v:=unsafe{a[i+2]};if v<i64(-10000)||v>i64(10000){return i64(-1)};x[i]=f64(v);idx[i]=i}
 mut remaining:=int(n);mut accepted:=0;mut removed:=[3]int{}
 for step in 1..int(limit)+1{mut mean:=f64(0);for i in 0..remaining{mean+=x[i]};mean/=f64(remaining);mut ss:=f64(0);for i in 0..remaining{d:=x[i]-mean;ss+=d*d};sd:=math.sqrt(ss/f64(remaining-1));if sd==0{break};mut worst:=0;mut largest:=f64(-1);for i in 0..remaining{d:=math.abs(x[i]-mean);if d>largest{largest=d;worst=i}};removed[step-1]=idx[worst];if largest/sd>critical[remaining]{accepted=step};remaining--;x[worst]=x[remaining];idx[worst]=idx[remaining]}
 mut mask:=i64(0);for i in 0..accepted{mask|=i64(1)<<u64(removed[i])};return mask
}
