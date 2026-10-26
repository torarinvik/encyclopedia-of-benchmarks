// Clean-room TSVC s471 profile; see package rights note.
const MAX_N:i64=32;const MAX_INPUT_LENGTH:usize=130;
fn put64(out:[*c]u8,pos:usize,v:i64)void{const bits:u64=@bitCast(v);for(0..8)|j|out[pos+j]=@truncate(bits>>@intCast(8*j));}
pub export fn tsvc_s471_ordered_two_vector_map(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length<6 or length>MAX_INPUT_LENGTH)return -1;
 const rn=input[0];const rp=input[1];if(rn<1 or rn>MAX_N or rp<1 or rp>4 or length!=2+4*@as(usize,@intCast(rn)))return -1;
 const n:usize=@intCast(rn);const passes:usize=@intCast(rp);var x=[_]f64{0.0}**32;var b=[_]f64{0.0}**32;var c=[_]f64{0.0}**32;var d=[_]f64{0.0}**32;var e=[_]f64{0.0}**32;
 for(0..n)|i|{const bv=input[2+i];const cv=input[2+n+i];const dv=input[2+2*n+i];const ev=input[2+3*n+i];if(bv< -2 or bv>2 or cv< -2 or cv>2 or dv< -2 or dv>2 or ev< -2 or ev>2)return -1;b[i]=@floatFromInt(bv);c[i]=@floatFromInt(cv);d[i]=@floatFromInt(dv);e[i]=@floatFromInt(ev);}
 const bytes=16*n;if(output==null or capacity<bytes)return -2;
 for(0..passes)|_|{for(0..n)|i|{x[i]=b[i]+d[i]*d[i];b[i]=c[i]+d[i]*e[i];}}
 for(0..n)|i|{put64(output,8*i,@intFromFloat(x[i]));put64(output,8*(n+i),@intFromFloat(b[i]));}return @intCast(bytes);
}
