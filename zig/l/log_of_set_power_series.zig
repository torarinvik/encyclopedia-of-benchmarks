const modulus:i64=998244353;
pub export fn log_of_set_power_series(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize) i64 {
    if (input==null or length<2 or length>33 or input[0]<0 or input[0]>5) return -1;
    const size=@as(usize,1) << @as(u6,@intCast(input[0]));
    if (length!=1+size or input[1]!=1) return -1;
    for (0..size) |i| { if (input[1+i]<0 or input[1+i]>=modulus) return -1; }
    if (output==null or capacity<8*size) return -2;
    var coefficients:[32]i64=@splat(0);
    for (1..size) |mask| {
        const pivot=mask & (~mask+1);
        var sub=(mask-1)&mask; var sum:i64=0;
        while (sub!=0) {
            if (sub & pivot != 0) sum=@mod(sum+coefficients[sub]*input[1+(mask^sub)],modulus);
            sub=(sub-1)&mask;
        }
        coefficients[mask]=@mod(input[1+mask]-sum+modulus,modulus);
    }
    for (0..size) |i| {
        const bits:u64=@intCast(coefficients[i]);
        for (0..8) |byte| output[8*i+byte]=@truncate(bits >> @as(u6,@intCast(8*byte)));
    }
    return @intCast(8*size);
}
