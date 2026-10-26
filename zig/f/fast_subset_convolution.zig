const MOD: i64 = 998244353;
fn rank(mask: usize) usize { return @popCount(mask); }
fn put(output: [*c]u8, off: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[off+b] = @truncate(bits >> @intCast(8*b));
}
pub export fn fast_subset_convolution(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input==null or length<3 or length>33)return -1;
    const n0=input[0];if(n0<0 or n0>4)return -1;
    const n:usize=@intCast(n0);const size:usize=@as(usize,1)<<@intCast(n);
    if(length!=1+2*size)return -1;
    for(0..2*size)|i|if(input[1+i]<0 or input[1+i]>=MOD)return -1;
    var f = [_][16]i64{[_]i64{0} ** 16} ** 5;
    var g = [_][16]i64{[_]i64{0} ** 16} ** 5;
    var h = [_][16]i64{[_]i64{0} ** 16} ** 5;
    for(0..size)|s|{const r=rank(s);f[r][s]=input[1+s];g[r][s]=input[1+size+s];}
    for(0..n)|bit|{for(0..size)|s|{if(s&(@as(usize,1)<<@intCast(bit))!=0){const other=s^(@as(usize,1)<<@intCast(bit));for(0..n+1)|r|{f[r][s]=@mod(f[r][s]+f[r][other],MOD);g[r][s]=@mod(g[r][s]+g[r][other],MOD);}}}}
    for(0..size)|s|{for(0..n+1)|r|{var sum:i64=0;for(0..r+1)|i|sum=@mod(sum+f[i][s]*g[r-i][s],MOD);h[r][s]=sum;}}
    for(0..n)|bit|{for(0..size)|s|{if(s&(@as(usize,1)<<@intCast(bit))!=0){const other=s^(@as(usize,1)<<@intCast(bit));for(0..n+1)|r|h[r][s]=@mod(h[r][s]-h[r][other]+MOD,MOD);}}}
    const required=size*8;if(capacity<required or output==null)return -2;
    for(0..size)|s|put(output,8*s,h[rank(s)][s]);return @intCast(required);
}
