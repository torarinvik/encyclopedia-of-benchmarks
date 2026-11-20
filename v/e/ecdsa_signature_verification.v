module ecdsa_signature_verification
struct Point { infinity bool; x i64; y i64 }
fn md(v i64,m i64)i64{r:=v%m;return if r<0 {r+m}else{r}}
fn inverse(v0 i64,m i64)i64{mut old_r:=m;mut r:=md(v0,m);mut old_t:=i64(0);mut t:=i64(1);for r!=0{q:=old_r/r;nr:=old_r-q*r;nt:=old_t-q*t;old_r=r;r=nr;old_t=t;t=nt};return if old_r==1 {md(old_t,m)}else{i64(0)}}
fn inf()Point{return Point{infinity:true}}
fn add(u Point,v Point)Point{if u.infinity{return v};if v.infinity{return u};if u.x==v.x&&md(u.y+v.y,17)==0{return inf()};mut num:=i64(0);mut den:=i64(0);if u.x==v.x&&u.y==v.y{num=md(3*u.x*u.x+2,17);den=md(2*u.y,17)}else{num=md(v.y-u.y,17);den=md(v.x-u.x,17)};slope:=md(num*inverse(den,17),17);x:=md(slope*slope-u.x-v.x,17);return Point{false,x,md(slope*(u.x-x)-u.y,17)}}
fn mul(q0 Point,k0 i64)Point{mut q:=q0;mut k:=k0;mut result:=inf();for k>0{if k&1!=0{result=add(result,q)};k>>=1;if k>0{q=add(q,q)}};return result}
fn on_curve(q Point)bool{return md(q.y*q.y-q.x*q.x*q.x-2*q.x-2,17)==0}
@[export:'ecdsa_signature_verification']
pub fn ecdsa_signature_verification(v &i64,n usize,mut o &u8,cap usize)i64{if unsafe{v==nil}||n!=11{return -1};unsafe{p:=v[0];a:=v[1];b:=v[2];gx:=v[3];gy:=v[4];order:=v[5];qx:=v[6];qy:=v[7];z:=v[8];r:=v[9];s:=v[10];if p!=17||a!=2||b!=2||gx!=5||gy!=1||order!=19{return -1};if md(4*a*a*a+27*b*b,p)==0||qx<0||qx>=p||qy<0||qy>=p||z<0||z>31||r<1||r>=order||s<1||s>=order{return -1};g:=Point{false,gx,gy};q:=Point{false,qx,qy};if !on_curve(g)||!on_curve(q)||!mul(g,order).infinity||!mul(q,order).infinity{return -1};if o==nil||cap<1{return -2};w:=inverse(s,order);if w==0{return -1};u1:=z*w%order;u2:=r*w%order;check:=add(mul(g,u1),mul(q,u2));o[0]=u8(!check.infinity&&check.x%order==r);return 1}}
