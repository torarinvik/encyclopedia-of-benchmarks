package xtea
import "core:c"
@(export)
xtea :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length!=25||input[0]<1||input[0]>64 do return -1
 for i:=c.size_t(1);i<25;i+=1{if input[i]<0||input[i]>255 do return -1}
 if output==nil||capacity<8 do return -2
 v0:=u32(0);v1:=u32(0);k:=[4]u32{};for i:=0;i<4;i+=1{v0=(v0<<8)|u32(input[1+i]);v1=(v1<<8)|u32(input[5+i]);for j:=0;j<4;j+=1{k[i]=(k[i]<<8)|u32(input[9+i*4+j])}}sum:=u32(0);for r:=i64(0);r<input[0];r+=1{v0+=(((v1<<4^v1>>5)+v1)^(sum+k[sum&3]));sum+=0x9E3779B9;v1+=(((v0<<4^v0>>5)+v0)^(sum+k[(sum>>11)&3]))}for i:=0;i<4;i+=1{output[i]=u8(v0>>(24-8*i));output[4+i]=u8(v1>>(24-8*i))}return 8
}
