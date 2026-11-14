const modulus: i64=998244353;
fn power(initial: i64) i64 {
    var x=initial; var e: u32=998244351; var result: i64=1;
    while (e>0) {
        if (e&1!=0) result=@mod(result*x,modulus);
        x=@mod(x*x,modulus); e >>= 1;
    }
    return result;
}
pub export fn inv_of_formal_power_series_2d(input: [*c]const i64, length: usize,
                                              output: [*c]u8, capacity: usize) i64 {
    if (input==null or length<3 or length>66 or input[0]<1 or input[0]>8 or input[1]<1 or input[1]>8) return -1;
    const n: usize=@intCast(input[0]); const m: usize=@intCast(input[1]);
    if (length!=2+n*m or input[2]==0) return -1;
    for (0..n*m) |i| { if (input[2+i]<0 or input[2+i]>=modulus) return -1; }
    if (output==null or capacity<8*n*m) return -2;
    var g: [64]i64=@splat(0); const inverse=power(input[2]); g[0]=inverse;
    for (0..n) |i| {
        for (0..m) |j| {
            if (i==0 and j==0) continue;
            var sum: i64=0;
            for (0..i+1) |a| {
                for (0..j+1) |b| {
                    if (a!=0 or b!=0) sum=@mod(sum+input[2+a*m+b]*g[(i-a)*m+j-b],modulus);
                }
            }
            g[i*m+j]=@mod(@mod(modulus-sum,modulus)*inverse,modulus);
        }
    }
    for (0..n*m) |i| {
        const bits: u64=@intCast(g[i]);
        for (0..8) |byte| output[8*i+byte]=@truncate(bits >> @as(u6,@intCast(8*byte)));
    }
    return @intCast(8*n*m);
}
