#[derive(Clone, Copy)]
struct Point { infinity: bool, x: i64, y: i64 }
fn md(v:i64,m:i64)->i64 { let r=v%m; if r<0 {r+m} else {r} }
fn inv(v:i64,m:i64)->i64 {
    let (mut old_r,mut r)=(m,md(v,m)); let (mut old_t,mut t)=(0,1);
    while r!=0 { let q=old_r/r; let nr=old_r-q*r;let nt=old_t-q*t;old_r=r;r=nr;old_t=t;t=nt; }
    if old_r==1 {md(old_t,m)} else {0}
}
fn infinity()->Point { Point{infinity:true,x:0,y:0} }
fn add(u:Point,v:Point)->Point {
    if u.infinity{return v} if v.infinity{return u}
    if u.x==v.x&&md(u.y+v.y,17)==0{return infinity()}
    let (num,den)=if u.x==v.x&&u.y==v.y {(md(3*u.x*u.x+2,17),md(2*u.y,17))} else {(md(v.y-u.y,17),md(v.x-u.x,17))};
    let slope=md(num*inv(den,17),17);let x=md(slope*slope-u.x-v.x,17);
    Point{infinity:false,x,y:md(slope*(u.x-x)-u.y,17)}
}
fn mul(mut point:Point,mut k:i64)->Point { let mut result=infinity();while k>0 {if k&1!=0{result=add(result,point)}k>>=1;if k>0{point=add(point,point)}}result }
fn on_curve(q:Point)->bool { md(q.y*q.y-q.x*q.x*q.x-2*q.x-2,17)==0 }
#[no_mangle]
pub unsafe extern "C" fn ecdsa_signature_verification(v:*const i64,n:usize,o:*mut u8,cap:usize)->i64 {
    if v.is_null()||n!=11{return -1}
    let p=*v;let a=*v.add(1);let b=*v.add(2);let gx=*v.add(3);let gy=*v.add(4);let order=*v.add(5);
    let qx=*v.add(6);let qy=*v.add(7);let z=*v.add(8);let r=*v.add(9);let s=*v.add(10);
    if p!=17||a!=2||b!=2||gx!=5||gy!=1||order!=19{return -1}
    if md(4*a*a*a+27*b*b,p)==0||qx<0||qx>=p||qy<0||qy>=p||z<0||z>31||r<1||r>=order||s<1||s>=order{return -1}
    let g=Point{infinity:false,x:gx,y:gy};let q=Point{infinity:false,x:qx,y:qy};
    if !on_curve(g)||!on_curve(q)||!mul(g,order).infinity||!mul(q,order).infinity{return -1}
    if o.is_null()||cap<1{return -2}
    let w=inv(s,order);if w==0{return -1}
    let u1=z*w%order;let u2=r*w%order;let point=add(mul(g,u1),mul(q,u2));
    *o=(!point.infinity&&point.x%order==r) as u8;1
}
