fn crc_byte(mut value: u8, mut crc: u16) -> u16 {
    for _ in 0..8 { let mix=(value&1)^(crc as u8&1); value>>=1; if mix!=0 {crc^=0x4002;} crc>>=1; if mix!=0 {crc|=0x8000;} else {crc&=0x7fff;} }
    crc
}
fn crc16(value: i16, crc: u16) -> u16 { let bits=value as u16; crc_byte((bits>>8) as u8,crc_byte(bits as u8,crc)) }
fn matrix_sum(c: &[i32;9], clip: i16) -> i16 { let (mut tmp,mut prev,mut ret)=(0i32,0i32,0i16);for &cur in c {tmp+=cur;if tmp>clip as i32 {ret+=10;tmp=0;}else if cur>prev {ret+=1;}prev=cur;}ret }
fn put_i64(output: &mut [u8], at: usize, value: i64) { output[at..at+8].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn coremark_matrix_manipulation(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64 {
    if input.is_null()||length!=19{return -1;}let v=core::slice::from_raw_parts(input,length);let raw=v[0];if !(0..=15).contains(&raw){return -1;}
    let mut a=[0i16;9];let mut b=[0i16;9];for i in 0..9{if !(0..=127).contains(&v[1+i])||!(0..=127).contains(&v[10+i]){return -1;}a[i]=v[1+i] as i16;b[i]=v[10+i] as i16;}
    if output.is_null()||capacity<112{return -2;}let value=raw as i16;let clip=value-4096;let mut c=[0i32;9];
    for x in &mut a{*x+=value;}
    for i in 0..9{c[i]=a[i] as i32*value as i32;}
    let mut sums=[0i16;4];sums[0]=matrix_sum(&c,clip);
    for i in 0..3{c[i]=0;for j in 0..3{c[i]+=a[i*3+j] as i32*b[j] as i32;}}
    sums[1]=matrix_sum(&c,clip);
    for i in 0..3{for j in 0..3{c[i*3+j]=0;for k in 0..3{c[i*3+j]+=a[i*3+k] as i32*b[k*3+j] as i32;}}}
    sums[2]=matrix_sum(&c,clip);
    for i in 0..3{for j in 0..3{c[i*3+j]=0;for k in 0..3{let t=a[i*3+k] as i32*b[k*3+j] as i32;c[i*3+j]+=((t>>2)&0xf)*((t>>5)&0x7f);}}}
    sums[3]=matrix_sum(&c,clip);let mut crc=0u16;for &s in &sums{crc=crc16(s,crc);}for x in &mut a{*x-=value;}
    let mut result=[0i64;14];result[0]=crc as i64;for i in 0..4{result[i+1]=sums[i] as i64;}for i in 0..9{result[i+5]=a[i] as i64;}
    let bytes=core::slice::from_raw_parts_mut(output,112);for i in 0..14{put_i64(bytes,i*8,result[i]);}112
}
