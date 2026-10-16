use std::slice;
fn re(x:f64)->i64{let f=x.floor();let q=f as i64;let d=x-f;if d<0.5{q}else if d>0.5{q+1}else if q&1==0{q}else{q+1}}
#[no_mangle]
pub extern "C" fn rgbhsvconversion(v:*const i64,n:usize)->i64{
 if v.is_null()||n!=4{return -1}let a=unsafe{slice::from_raw_parts(v,n)};
 if a[0]==0{if a[1]<0||a[1]>360000||a[2]<0||a[2]>1000||a[3]<0||a[3]>1000{return -1}let h=a[1]as f64/1000.0;let s=a[2]as f64/1000.0;let val=a[3]as f64/1000.0;let c=val*s;let sec=h/60.0;let x=c*(1.0-((sec%2.0)-1.0).abs());let m=val-c;let(r,g,b)=if sec<=1.0{(c+m,x+m,m)}else if sec<=2.0{(x+m,c+m,m)}else if sec<=3.0{(m,c+m,x+m)}else if sec<=4.0{(m,x+m,c+m)}else if sec<=5.0{(x+m,m,c+m)}else{(c+m,m,x+m)};return (re(255.0*r)<<16)|(re(255.0*g)<<8)|re(255.0*b)}
 if a[0]!=1||a[1]<0||a[1]>255||a[2]<0||a[2]>255||a[3]<0||a[3]>255{return -1}let r=a[1]as f64/255.0;let g=a[2]as f64/255.0;let b=a[3]as f64/255.0;let mx=r.max(g.max(b));let mn=r.min(g.min(b));let c=mx-mn;let s=if mx==0.0{0.0}else{c/mx};let mut h=if c==0.0{0.0}else if mx==r{60.0*((g-b)/c)}else if mx==g{60.0*(2.0+(b-r)/c)}else{60.0*(4.0+(r-g)/c)};h=(h+360.0)%360.0;let qh=re(h*1000.0);let qs=re(s*1_000_000.0);let qv=re(mx*1_000_000.0);(qh<<40)|(qs<<20)|qv
}
