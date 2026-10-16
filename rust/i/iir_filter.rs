fn put64(o:&mut[u8],i:usize,x:f64){o[i*8..i*8+8].copy_from_slice(&x.to_le_bytes());}
#[no_mangle]
pub extern "C" fn iir_filter(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<7||n>26{return -1}let a0=unsafe{std::slice::from_raw_parts(v,n)};if a0[0]<1||a0[0]>3||a0[1]<1||a0[1]>16{return -1}let order=a0[0] as usize;let samples=a0[1] as usize;if n!=4+2*order+samples{return -1}
 let mut a=[0.0f64;4];let mut b=[0.0f64;4];let mut xh=[0.0f64;3];let mut yh=[0.0f64;3];for i in 0..=order{let av=a0[2+i];let bv=a0[3+order+i];if av < -500||av>2000||bv < -500||bv>500{return -1}a[i]=av as f64/1000.0;b[i]=bv as f64/1000.0;}if a[0]<0.5{return -1}for i in 0..samples{if !(-1000..=1000).contains(&a0[4+2*order+i]){return -1}}
 let bytes=samples*8;if out.is_null()||cap<bytes{return -2}let o=unsafe{std::slice::from_raw_parts_mut(out,bytes)};for s in 0..samples{let x=a0[4+2*order+s] as f64/1000.0;let mut y=0.0;for i in 1..=order{y+=b[i]*xh[i-1]-a[i]*yh[i-1];}y=(y+b[0]*x)/a[0];for i in (1..order).rev(){xh[i]=xh[i-1];yh[i]=yh[i-1];}xh[0]=x;yh[0]=y;put64(o,s,y);}bytes as i64
}
