module rgbhsvconversion
import math
fn round_even(x f64)i64{f:=math.floor(x);q:=i64(f);d:=x-f;if d<0.5{return q};if d>0.5{return q+1};return if q&1==0{q}else{q+1}}
@[export: 'rgbhsvconversion']
pub fn rgbhsvconversion(v &i64,n usize)i64{
 if isnil(v)||n!=4{return -1}
 if v[0]==0{if v[1]<0||v[1]>360000||v[2]<0||v[2]>1000||v[3]<0||v[3]>1000{return -1};h:=f64(v[1])/1000.0;s:=f64(v[2])/1000.0;value:=f64(v[3])/1000.0;c:=value*s;sec:=h/60.0;x:=c*(1.0-math.abs((sec-math.floor(sec/2.0)*2.0)-1.0));m:=value-c;mut r:=f64(0);mut g:=f64(0);mut b:=f64(0);if sec<=1{r=c+m;g=x+m;b=m}else if sec<=2{r=x+m;g=c+m;b=m}else if sec<=3{r=m;g=c+m;b=x+m}else if sec<=4{r=m;g=x+m;b=c+m}else if sec<=5{r=x+m;g=m;b=c+m}else{r=c+m;g=m;b=x+m};return (round_even(255*r)<<16)|(round_even(255*g)<<8)|round_even(255*b)}
 if v[0]!=1||v[1]<0||v[1]>255||v[2]<0||v[2]>255||v[3]<0||v[3]>255{return -1};r:=f64(v[1])/255.0;g:=f64(v[2])/255.0;b:=f64(v[3])/255.0;mx:=math.max(r,math.max(g,b));mn:=math.min(r,math.min(g,b));c:=mx-mn;s:=if mx==0{f64(0)}else{c/mx};mut h:=f64(0);if c==0{h=0}else if mx==r{h=60*((g-b)/c)}else if mx==g{h=60*(2+(b-r)/c)}else{h=60*(4+(r-g)/c)};h=h+360-math.floor((h+360)/360.0)*360.0;qh:=round_even(h*1000);qs:=round_even(s*1000000);qv:=round_even(mx*1000000);return(qh<<40)|(qs<<20)|qv
}
