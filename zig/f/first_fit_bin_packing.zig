fn put(out:[*c]u8,offset:usize,x:i64)void{const u:u64=@bitCast(x);for(0..8)|b|out[offset+b]=@truncate(u>>@intCast(8*b));}
pub export fn first_fit_bin_packing(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null or length<1 or length>65)return -1;const n0=input[0];if(n0<0 or n0>64)return -1;const n:usize=@intCast(n0);if(length!=1+n)return -1;
    for(0..n)|i|if(input[i+1]<1 or input[i+1]>1_000_000)return -1;
    var loads=[_]i64{0}**64;var ids=[_]i64{0}**64;var bins:usize=0;
    for(0..n)|i|{const size=input[i+1];var b:usize=0;while(b<bins and loads[b]+size>1_000_000):(b+=1){}if(b==bins){loads[bins]=size;bins+=1;}else{loads[b]+=size;}ids[i]=@intCast(b);}
    const required=(n+1)*8;if(capacity<required or output==null)return -2;put(output,0,@intCast(bins));for(0..n)|i|put(output,8*(i+1),ids[i]);return @intCast(required);
}
