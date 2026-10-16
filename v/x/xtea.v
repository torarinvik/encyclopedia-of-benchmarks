module xtea
@[export:'xtea']
pub fn xtea(input &i64,length usize,mut output &u8,capacity usize)i64{
 if unsafe{input==nil}||length!=25{return -1};unsafe{if input[0]<1||input[0]>64{return -1};for i in 1..25{if input[i]<0||input[i]>255{return -1}}if unsafe{output==nil}||capacity<8{return -2};mut v0:=u32(0);mut v1:=u32(0);mut k:=[4]u32{};for i in 0..4{v0=(v0<<8)|u32(input[1+i]);v1=(v1<<8)|u32(input[5+i]);for j in 0..4{k[i]=(k[i]<<8)|u32(input[9+i*4+j])}}mut sum:=u32(0);for _ in 0..int(input[0]){v0+=(((v1<<4^v1>>5)+v1)^(sum+k[sum&3]));sum+=u32(0x9E3779B9);v1+=(((v0<<4^v0>>5)+v0)^(sum+k[(sum>>11)&3]))}for i in 0..4{output[i]=u8(v0>>(24-8*i));output[4+i]=u8(v1>>(24-8*i))}return 8}
}
