package uniform_crossover

put_i64_le :: proc "contextless" (output:[^]u8,offset:int,value:i64){bits:=transmute(u64)value;for byte in 0..8{output[offset+byte]=u8(bits>>(8*byte))}}
@(export,link_name="uniform_crossover")
uniform_crossover :: proc "c" (input:[^]i64,length:uint,output:[^]u8,capacity:uint)->i64{
 if input==nil||length<4||length>193 do return -1
 n:=input[0];if n<1||n>64||length!=uint(1+3*n)do return -1
 for i:i64=0;i<n;i+=1{if input[1+i]!=0&&input[1+i]!=1 do return -1}
 for i:i64=0;i<2*n;i+=1{gene:=input[1+n+i];if gene < -2147483648||gene>2147483647 do return -1}
 count:=int(n);bytes:=16*count;if output==nil||capacity<uint(bytes)do return -2
 for i:=0;i<count;i+=1{alpha,p,q:=input[1+i],input[1+count+i],input[1+2*count+i];c1,c2:=p,q;if alpha==0{c1,c2=q,p};put_i64_le(output,i*8,c1);put_i64_le(output,(count+i)*8,c2)}
 return i64(bytes)
}
main :: proc() {}
