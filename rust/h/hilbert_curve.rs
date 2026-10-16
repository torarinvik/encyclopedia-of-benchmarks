fn reverse(o:&mut [i64;8192],start:usize,n:usize){for i in 0..n/2{let a=start+2*i;let b=start+2*(n-1-i);o.swap(a,b);o.swap(a+1,b+1);}}
fn curve(x:i64,y:i64,side:i64,level:i32,angle:i32,o:&mut [i64;8192],off:usize)->usize{
 let q=side/4;let p=[(x+q,y+q),(x-q,y+q),(x-q,y-q),(x+q,y-q)];let a=angle.rem_euclid(4);let mut r=[(0,0);4];for i in 0..4{r[i]=p[(i+a as usize)%4];}
 if level==1{for i in 0..4{o[off+2*i]=r[i].0;o[off+2*i+1]=r[i].1;}return 4;}
 let h=side/2;let n=curve(r[0].0,r[0].1,h,level-1,a+1,o,off);reverse(o,off,n);
 let n1=curve(r[1].0,r[1].1,h,level-1,a,o,off+2*n);let n2=curve(r[2].0,r[2].1,h,level-1,a,o,off+2*(n+n1));let n3=curve(r[3].0,r[3].1,h,level-1,a-1,o,off+2*(n+n1+n2));reverse(o,off+2*(n+n1+n2),n3);n+n1+n2+n3
}
#[no_mangle]
pub extern "C" fn hilbert_curve(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n!=2{return -1}let a=unsafe{std::slice::from_raw_parts(v,2)};if !(1..=6).contains(&a[0])||!(0..=3).contains(&a[1]){return -1}let l=a[0] as usize;let points=1usize<<(2*l);let bytes=points*16;if out.is_null()||cap<bytes{return -2}let mut coords=[0i64;8192];curve(0,0,1i64<<(l+1),l as i32,a[1] as i32,&mut coords,0);let dst=unsafe{std::slice::from_raw_parts_mut(out,bytes)};for i in 0..points*2{dst[i*8..i*8+8].copy_from_slice(&coords[i].to_le_bytes());}bytes as i64
}
