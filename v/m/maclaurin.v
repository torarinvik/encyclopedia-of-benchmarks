module maclaurin
import math
const bad=-1.0e300
fn fact(n i64) f64 {mut f:=1.0;for i:=i64(2);i<=n;i++{f*=f64(i)};return f}
fn term(m i64,x f64,i i64) f64 {mut e:=i;mut sign:=1.0;if m==1{e=2*i+1;if i%2!=0{sign=-1}}else if m==2{e=2*i;if i%2!=0{sign=-1}};if m==0{return math.pow(x,f64(e))/fact(e)};return sign/fact(e)*math.pow(x,f64(e))}
@[export:'maclaurin']
pub fn maclaurin(v &i64,n usize) f64 {if n!=3{return bad};unsafe{if v==nil{return bad};m:=v[0];xm:=v[1];em:=v[2];if m<0||m>2||xm < -2000||xm>2000||em<1||em>250{return bad};x:=f64(xm)/1000.0;error:=f64(em)/1000.0;mut coefficient:=0.0;mut result:=0.0;for i:=i64(0);i<32;i++{result+=coefficient;coefficient=term(m,x,i);if math.abs(coefficient)<=error{return result}};return bad}}
