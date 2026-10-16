#[no_mangle]
pub extern "C" fn scaled_exponential_linear_unit(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<3||n>259{return -1;}let v=unsafe{std::slice::from_raw_parts(v,n)};if !(0..=256).contains(&v[0])||n!=v[0] as usize+3||!(-10_000_000..=10_000_000).contains(&v[1])||!(-10_000_000..=10_000_000).contains(&v[2])||v[3..].iter().any(|&x|!(-20_000_000..=20_000_000).contains(&x)){return -1;}
 let count=v[0] as usize;let bytes=count*8;if out.is_null()||cap<bytes{return -2;}let alpha=v[1] as f64/1e6;let lambda=v[2] as f64/1e6;
 for i in 0..count{let x=v[i+3] as f64/1e6;let y=lambda*(if x>0.0{x}else{alpha*(x.exp()-1.0)});let q=(y*1e9+0.5).floor() as i64;unsafe{std::ptr::copy_nonoverlapping(q.to_le_bytes().as_ptr(),out.add(i*8),8);}}bytes as i64
}
