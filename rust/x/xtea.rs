#[no_mangle]
pub unsafe extern "C" fn xtea(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length!=25{return -1;}let a=std::slice::from_raw_parts(input,length);if !(1..=64).contains(&a[0])||a[1..].iter().any(|&x|!(0..=255).contains(&x)){return -1;}if output.is_null()||capacity<8{return -2;}
 let mut v0=0u32;let mut v1=0u32;let mut k=[0u32;4];for i in 0..4{v0=(v0<<8)|a[1+i] as u32;v1=(v1<<8)|a[5+i] as u32;for j in 0..4{k[i]=(k[i]<<8)|a[9+i*4+j] as u32;}}let mut sum=0u32;for _ in 0..a[0]{v0=v0.wrapping_add((((v1<<4 ^ v1>>5).wrapping_add(v1))^(sum.wrapping_add(k[(sum&3)as usize]))));sum=sum.wrapping_add(0x9E3779B9);v1=v1.wrapping_add((((v0<<4 ^ v0>>5).wrapping_add(v0))^(sum.wrapping_add(k[((sum>>11)&3)as usize]))));}let out=std::slice::from_raw_parts_mut(output,capacity);for i in 0..4{out[i]=(v0>>(24-8*i))as u8;out[4+i]=(v1>>(24-8*i))as u8;}8
}
