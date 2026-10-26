// Clean-room implementation of TSVC vpvpv; see package rights note.
const MAX_N: i64 = 32;
const MAX_INPUT_LENGTH: usize = 98;
fn store_i64_le(out:*mut u8,pos:usize,value:i64){let bits=value as u64;for j in 0..8{unsafe{out.add(pos+j).write((bits>>(8*j))as u8);}}}
#[no_mangle]
pub unsafe extern "C" fn tsvc_vpvpv_three_vector_add(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<5||length>MAX_INPUT_LENGTH{return -1;}let v=core::slice::from_raw_parts(input,length);
 if v[0]<1||v[0]>MAX_N||v[1]<1||v[1]>4||length!=2+3*v[0]as usize{return -1;}
 let n=v[0]as usize;let passes=v[1]as usize;let mut a=[0.0f64;MAX_N as usize];let mut b=[0.0f64;MAX_N as usize];let mut c=[0.0f64;MAX_N as usize];
 for i in 0..n{let av=v[2+i];let bv=v[2+n+i];let cv=v[2+2*n+i];if !(-2..=2).contains(&av)||!(-2..=2).contains(&bv)||!(-2..=2).contains(&cv){return -1;}a[i]=av as f64;b[i]=bv as f64;c[i]=cv as f64;}
 let bytes=8*n;if output.is_null()||capacity<bytes{return -2;}
 for _ in 0..passes{for i in 0..n{a[i]+=b[i]+c[i];}}
 for i in 0..n{store_i64_le(output,8*i,a[i]as i64);}bytes as i64
}
