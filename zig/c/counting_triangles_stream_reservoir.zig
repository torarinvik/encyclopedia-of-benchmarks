fn put_i64(out:[*c]u8,offset:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[offset+b]=@truncate(bits>>@intCast(8*b));}

export fn counting_triangles_stream_reservoir(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null or length<6 or length>114)return -1;
    const n0=input[0];const m0=input[1];if(n0<2 or n0>8 or m0<1 or m0>28 or length!=2+4*@as(usize,@intCast(m0)))return -1;
    const m:usize=@intCast(m0);var seen=[_]bool{false}**64;var eu=[_]i64{0}**28;var ev=[_]i64{0}**28;
    for(0..m)|i|{const u=input[2+2*i];const v=input[3+2*i];if(u<0 or v<=u or v>=n0)return -1;const ui:usize=@intCast(u);const vi:usize=@intCast(v);const key=ui*8+vi;if(seen[key])return -1;seen[key]=true;seen[vi*8+ui]=true;eu[i]=u;ev[i]=v;}
    const base=2+2*m;for(1..m+1)|t|{for(0..2)|s|{const r=input[base+2*(t-1)+s];if(r<0 or r>=@as(i64,@intCast(t)))return -1;}}
    var su=[_]i64{-1}**2;var sv=[_]i64{-1}**2;var staged=[_]i64{0}**112;var at:usize=0;
    for(1..m+1)|t|{for(0..2)|s|{if(input[base+2*(t-1)+s]==0){su[s]=eu[t-1];sv[s]=ev[t-1];}}for(0..2)|s|{staged[at]=su[s];at+=1;staged[at]=sv[s];at+=1;}}
    const bytes=16*m;if(output==null or capacity<bytes)return -2;for(0..at)|i|put_i64(output,8*i,staged[i]);return @intCast(bytes);
}
