/// Emit exact source float medians widened to little-endian binary64 bytes.
const MAX_STREAM:usize=128;
fn putF64Le(out:[*]u8,offset:usize,value:f64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[offset+b]=@truncate(bits>>@intCast(8*b));}
pub export fn windowed_median(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length<3)return -1;const wv=input[0];const nv=input[1];if(wv<1 or wv>64 or nv<1 or nv>MAX_STREAM)return -1;const w:usize=@intCast(wv);const n:usize=@intCast(nv);if(length!=n+2)return -1
 const values=input[2..][0..n];for(values)|v|if(v < -1_000_000 or v>1_000_000)return -1;
 if(capacity<n*8 or output==null)return -2
 var sorted:[64]i64=@splat(0);var active:usize=0
 for(0..n)|i|{if(i>=w){const old=values[i-w];var p:usize=0;while(p<active and sorted[p]!=old):(p+=1){}if(p==active)return -1;var j=p+1;while(j<active):(j+=1){sorted[j-1]=sorted[j];}active-=1;}
  const value=values[i];var p:usize=0;while(p<active and sorted[p]<value):(p+=1){}var j=active;while(j>p){sorted[j]=sorted[j-1];j-=1;}sorted[p]=value;active+=1
  const median:f32=if(active%2==1) @floatFromInt(sorted[active/2]) else 0.5*@as(f32,@floatFromInt(sorted[active/2-1]))+0.5*@as(f32,@floatFromInt(sorted[active/2]));putF64Le(output,i*8,@floatCast(median));}
 return @intCast(n*8);
}
