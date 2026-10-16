package star_delta_conversions
import "core:math"
@(export)
star_delta_conversions :: proc "c" (v: [^]i64, n: u64) -> i64 {
 if v==nil||n!=4||(v[0]!=0&&v[0]!=1) do return -1
 for i:=u64(1);i<4;i+=1{if v[i]<1000||v[i]>100000 do return -1}
 a,b,c:=f64(v[1]),f64(v[2]),f64(v[3]);var out:[3]f64
 if v[0]==0{p:=a*b+b*c+c*a;out=[3]f64{p/a,p/b,p/c}}else{s:=a+b+c;out=[3]f64{b*c/s,c*a/s,a*b/s}}
 h:u64=0xcbf29ce484222325
 for x in out{q:=i64(math.floor(x+0.5));u:=transmute(u64,q);for j:=u32(0);j<8;j+=1{h=(h^((u>>(8*j))&255))*0x100000001b3}}
 return transmute(i64,h)
}
