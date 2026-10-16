export fn xtea(input:?[*]const i64,length:usize,output:?[*]u8,capacity:usize)i64{
 if(input==null or length!=25)return -1;const a=input.?[0..length];if(a[0]<1 or a[0]>64)return -1;for(1..25)|i|{if(a[i]<0 or a[i]>255)return -1;}if(output==null or capacity<8)return -2;
 var v0:u32=0;var v1:u32=0;var k=[_]u32{0,0,0,0};for(0..4)|i|{v0=(v0<<8)|@as(u32,@intCast(a[1+i]));v1=(v1<<8)|@as(u32,@intCast(a[5+i]));for(0..4)|j|{k[i]=(k[i]<<8)|@as(u32,@intCast(a[9+i*4+j]));}}var sum:u32=0;for(0..@intCast(a[0]))|_|{v0+%=(((v1<<4 ^ v1>>5)+%v1)^(sum+%k[@intCast(sum&3)]));sum+%=0x9E3779B9;v1+%=(((v0<<4 ^ v0>>5)+%v0)^(sum+%k[@intCast((sum>>11)&3)]));}const out=output.?[0..capacity];for(0..4)|i|{out[i]=@truncate(v0>>(24-8*i));out[4+i]=@truncate(v1>>(24-8*i));}return 8;
}
