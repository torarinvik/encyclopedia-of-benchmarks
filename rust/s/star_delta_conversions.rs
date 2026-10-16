use std::slice;
#[no_mangle]
pub extern "C" fn star_delta_conversions(v:*const i64,n:usize)->i64{
 if v.is_null()||n!=4{return -1}let a=unsafe{slice::from_raw_parts(v,n)};if (a[0]!=0&&a[0]!=1)||a[1..].iter().any(|x|*x<1000||*x>100000){return -1}
 let(x,y,z)=(a[1]as f64,a[2]as f64,a[3]as f64);let out=if a[0]==0{let p=x*y+y*z+z*x;[p/x,p/y,p/z]}else{let s=x+y+z;[y*z/s,z*x/s,x*y/s]};let mut h:u64=0xcbf29ce484222325;
 for value in out{let q=(value+0.5).floor()as i64;let u=q as u64;for j in 0..8{h^=(u>>(8*j))&255;h=h.wrapping_mul(0x100000001b3)}}h as i64
}
