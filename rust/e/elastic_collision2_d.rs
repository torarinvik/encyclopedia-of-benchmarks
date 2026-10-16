use std::slice;
#[no_mangle]
pub extern "C" fn elastic_collision2_d(v:*const i64,n:usize)->i64{
 if v.is_null()||n!=12{return -1} let a=unsafe{slice::from_raw_parts(v,n)};
 for &i in &[0usize,1,6,7]{if a[i]< -200000||a[i]>200000{return -1}}
 for &i in &[2usize,3,8,9]{if a[i]< -5000||a[i]>5000{return -1}}
 if a[4]<1000||a[4]>100000||a[10]<1000||a[10]>100000||a[5]<1||a[5]>10000||a[11]<1||a[11]>10000{return -1}
 let dx=(a[6]-a[0])as f64;let dy=(a[7]-a[1])as f64;let dist=dx.hypot(dy);if dist==0.0{return -1}
 let(mut ox,mut oy)=(a[2]as f64,a[3]as f64);
 if !(dist<(a[5]+a[11])as f64){let(nx,ny)=(dx/dist,dy/dist);let rv=((a[8]-a[2])as f64)*nx+((a[9]-a[3])as f64)*ny;if rv<=0.0{let j=-2.0*rv/(1.0/a[4]as f64+1.0/a[10]as f64);ox-=j*nx/a[4]as f64;oy-=j*ny/a[4]as f64;}}
 let(qx,qy)=((ox+0.5).floor()as i64,(oy+0.5).floor()as i64);if qx< -32768||qx>32767||qy< -32768||qy>32767{return -1}((qx&0xffff)<<16)|(qy&0xffff)
}
