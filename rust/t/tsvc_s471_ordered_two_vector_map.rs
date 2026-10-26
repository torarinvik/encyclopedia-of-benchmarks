// Clean-room TSVC s471 profile; see package rights note.
const MAX_N:i64=32;const MAX_INPUT_LENGTH:usize=130;
fn put64(out:*mut u8,pos:usize,v:i64){let bits=v as u64;for j in 0..8{unsafe{out.add(pos+j).write((bits>>(8*j))as u8);}}}
#[no_mangle]
pub unsafe extern "C" fn tsvc_s471_ordered_two_vector_map(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<6||length>MAX_INPUT_LENGTH{return -1;}let v=core::slice::from_raw_parts(input,length);
 if v[0]<1||v[0]>MAX_N||v[1]<1||v[1]>4||length!=2+4*v[0]as usize{return -1;}
 let n=v[0]as usize;let passes=v[1]as usize;let mut x=[0.0f64;MAX_N as usize];let mut b=[0.0f64;MAX_N as usize];let mut c=[0.0f64;MAX_N as usize];let mut d=[0.0f64;MAX_N as usize];let mut e=[0.0f64;MAX_N as usize];
 for i in 0..n{let bv=v[2+i];let cv=v[2+n+i];let dv=v[2+2*n+i];let ev=v[2+3*n+i];if !(-2..=2).contains(&bv)||!(-2..=2).contains(&cv)||!(-2..=2).contains(&dv)||!(-2..=2).contains(&ev){return -1;}b[i]=bv as f64;c[i]=cv as f64;d[i]=dv as f64;e[i]=ev as f64;}
 let bytes=16*n;if output.is_null()||capacity<bytes{return -2;}
 for _ in 0..passes{for i in 0..n{x[i]=b[i]+d[i]*d[i];b[i]=c[i]+d[i]*e[i];}}
 for i in 0..n{put64(output,8*i,x[i]as i64);put64(output,8*(n+i),b[i]as i64);}bytes as i64
}
