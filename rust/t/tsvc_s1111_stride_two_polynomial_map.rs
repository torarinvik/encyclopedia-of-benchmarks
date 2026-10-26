// Clean-room TSVC s1111 profile; see package rights note.
const MAX_N:usize=32;const MAX_INPUT_LENGTH:usize=161;
fn put64(out:*mut u8,pos:usize,v:i64){let bits=v as u64;for j in 0..8{unsafe{out.add(pos+j).write((bits>>(8*j))as u8);}}}
#[no_mangle]
pub unsafe extern "C" fn tsvc_s1111_stride_two_polynomial_map(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<6||length>MAX_INPUT_LENGTH{return -1;}let v=core::slice::from_raw_parts(input,length);if v[0]<1||v[0]>MAX_N as i64{return -1;}let n=v[0]as usize;if length!=1+5*n{return -1;}
 let mut a=[0i64;64];let mut b=[0i64;32];let mut c=[0i64;32];let mut d=[0i64;32];let mut off=1;for i in 0..2*n{let x=v[off+i];if !(-2..=2).contains(&x){return -1;}a[i]=x;}off+=2*n;
 for i in 0..n{let x=v[off+i];if !(-2..=2).contains(&x){return -1;}b[i]=x;}off+=n;for i in 0..n{let x=v[off+i];if !(-2..=2).contains(&x){return -1;}c[i]=x;}off+=n;for i in 0..n{let x=v[off+i];if !(-2..=2).contains(&x){return -1;}d[i]=x;}
 let bytes=16*n;if output.is_null()||capacity<bytes{return -2;}for i in 0..n{a[2*i]=c[i]*b[i]+d[i]*b[i]+c[i]*c[i]+d[i]*b[i]+d[i]*c[i];}for i in 0..2*n{put64(output,8*i,a[i]);}(2*n)as i64
}
