/// Static range minimum queries using a sparse table.
const MAX_N:usize=64;
fn putI64Le(out:[*]u8,offset:usize,value:i64) void {const bits:u64=@bitCast(value);for(0..8)|b|out[offset+b]=@truncate(bits>>@intCast(8*b));}
pub export fn range_minimum_query(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize) i64 {
    if(input==null or length<4)return -1;if(input[0]<1 or input[0]>MAX_N)return -1;const n:usize=@intCast(input[0]);const qp=1+n
    if(length<=qp or input[qp]<1 or input[qp]>64)return -1;const q:usize=@intCast(input[qp]);if(length!=qp+1+2*q)return -1
    var values:[MAX_N]i64=@splat(0);for(0..n)|i|{values[i]=input[1+i];if(values[i]<-1000 or values[i]>1000)return -1;}
    if(capacity<q*8 or (q>0 and output==null))return -2
    var table:[7][MAX_N]usize=@splat(@splat(0));for(0..n)|i|table[0][i]=i
    var k:usize=1;while((@as(usize,1)<<@intCast(k))<=n):(k+=1){const width:usize=@as(usize,1)<<@intCast(k);const half=width>>1;var i:usize=0;while(i+width<=n):(i+=1){const a=table[k-1][i];const b=table[k-1][i+half];table[k][i]=if(values[a]<values[b])a else b;}}
    const invalid:i64=-9223372036854775807-1
    for(0..q)|j|{const left=input[qp+1+2*j];const right=input[qp+2+2*j];var answer=invalid
        if(left>=0 and right>left and right<=n){const l:usize=@intCast(left);const r:usize=@intCast(right);const span=r-l;var level:usize=0;while((@as(usize,1)<<@intCast(level+1))<=span):(level+=1){}const width:usize=@as(usize,1)<<@intCast(level);const a=table[level][l];const b=table[level][r-width];answer=if(values[a]<values[b])values[a] else values[b];}
        putI64Le(output,j*8,answer);}
    return @intCast(q*8);
}
