module star_delta_conversions
import math
@[export: 'star_delta_conversions']
pub fn star_delta_conversions(v &i64,n usize)i64{
 if isnil(v)||n!=4||(v[0]!=0&&v[0]!=1){return -1}
 for i in 1..4{if v[i]<1000||v[i]>100000{return -1}}
 a:=f64(v[1]);b:=f64(v[2]);c:=f64(v[3]);mut out:=[3]f64{}
 if v[0]==0{p:=a*b+b*c+c*a;out=[p/a,p/b,p/c]}else{s:=a+b+c;out=[b*c/s,c*a/s,a*b/s]}
 mut h:=u64(0xcbf29ce484222325)
 for x in out{q:=i64(math.floor(x+0.5));u:=u64(q);for j in 0..8{h=(h^((u>>(8*j))&255))*u64(0x100000001b3)}}
 return i64(h)
}
