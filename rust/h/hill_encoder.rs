#[no_mangle]
pub extern "C" fn hill_encoder(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<10||n>74{return -1}let a=unsafe{std::slice::from_raw_parts(v,n)};if a[0]<0||a[0]>64||n!=10+a[0] as usize{return -1}let len=a[0] as usize;let padded=(len+2)/3*3;let mut text=[0i64;66];let mut key=[0i64;9];let mut result=[0i64;66];for i in 0..len{if !(65..=90).contains(&a[1+i]){return -1}text[i]=a[1+i]}for i in len..padded{text[i]=32}for i in 0..9{key[i]=a[1+len+i];if !(-2..=2).contains(&key[i]){return -1}}
 for off in (0..padded).step_by(3){for row in 0..3{let mut sum=0i64;for col in 0..3{sum+=key[row*3+col]*text[off+col]}if !(0..=65535).contains(&sum){return -1}result[off+row]=sum;}}
 let bytes=padded*8;if out.is_null()||cap<bytes{return -2}let dst=unsafe{std::slice::from_raw_parts_mut(out,bytes)};for i in 0..padded{dst[i*8..i*8+8].copy_from_slice(&result[i].to_le_bytes())}bytes as i64
}
