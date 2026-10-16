fn put64(out:&mut [u8],i:usize,x:f64){out[i*8..i*8+8].copy_from_slice(&x.to_le_bytes());}
#[no_mangle]
pub extern "C" fn euler_modified(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n!=2{return -1;}let a=unsafe{std::slice::from_raw_parts(v,n)};if a[0]<1||a[0]>8||a[1]<1||a[1]>4{return -1;}
 let steps=a[0] as usize;let bytes=(steps+1)*8;if out.is_null()||cap<bytes{return -2;}let o=unsafe{std::slice::from_raw_parts_mut(out,bytes)};
 let h=0.25f64;let mut x=0.0f64;let mut y=a[1] as f64;put64(o,0,y);
 for i in 0..steps{let f0=-2.0*x*y*y;let predictor=y+h*f0;let f1=-2.0*(x+h)*predictor*predictor;y=y+(h/2.0)*(f0+f1);x+=h;put64(o,i+1,y);}
 bytes as i64
}
