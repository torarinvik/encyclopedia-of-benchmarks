fn put_i64_le(output:[*]u8,offset:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|byte|output[offset+byte]=@truncate(bits>>@intCast(8*byte));}
export fn uniform_crossover(input:[*]const i64,length:usize,output:[*]u8,capacity:usize)i64{
 if(length<4 or length>193)return -1;const n=input[0];if(n<1 or n>64 or length!=@as(usize,@intCast(1+3*n)))return -1;
 for(0..@as(usize,@intCast(n)))|i|{const a=input[1+i];if(a!=0 and a!=1)return -1;}
 for(0..@as(usize,@intCast(2*n)))|i|{const gene=input[1+@as(usize,@intCast(n))+i];if(gene < -2147483648 or gene>2147483647)return -1;}
 const count:usize=@intCast(n);const bytes=16*count;if(capacity<bytes)return -2;
 for(0..count)|i|{const a=input[1+i];const p=input[1+count+i];const q=input[1+2*count+i];const c1=if(a==1)p else q;const c2=if(a==1)q else p;put_i64_le(output,i*8,c1);put_i64_le(output,(count+i)*8,c2);}return @intCast(bytes);
}
