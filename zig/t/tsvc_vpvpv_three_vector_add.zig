// Clean-room implementation of TSVC vpvpv; see package rights note.
const MAX_N: i64 = 32;
const MAX_INPUT_LENGTH: usize = 98;
fn storeI64Le(out:[*c]u8,pos:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|j|out[pos+j]=@truncate(bits>>@intCast(8*j));}
pub export fn tsvc_vpvpv_three_vector_add(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length<5 or length>MAX_INPUT_LENGTH)return -1;
 const rn=input[0];const rp=input[1];if(rn<1 or rn>MAX_N or rp<1 or rp>4 or length!=2+3*@as(usize,@intCast(rn)))return -1;
 const n:usize=@intCast(rn);const passes:usize=@intCast(rp);var a=[_]f64{0.0}**32;var b=[_]f64{0.0}**32;var c=[_]f64{0.0}**32;
 for(0..n)|i|{const av=input[2+i];const bv=input[2+n+i];const cv=input[2+2*n+i];if(av< -2 or av>2 or bv< -2 or bv>2 or cv< -2 or cv>2)return -1;a[i]=@floatFromInt(av);b[i]=@floatFromInt(bv);c[i]=@floatFromInt(cv);}
 const bytes=8*n;if(output==null or capacity<bytes)return -2;
 for(0..passes)|_|{for(0..n)|i|{a[i]+=b[i]+c[i];}}
 for(0..n)|i|storeI64Le(output,8*i,@intFromFloat(a[i]));return @intCast(bytes);
}
