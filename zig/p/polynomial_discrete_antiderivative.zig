const modulus: i64 = 998244353;
pub export fn polynomial_discrete_antiderivative(input: [*c]const i64, length: usize,
                                                 output: [*c]u8, capacity: usize) i64 {
    if (input==null or length<2 or length>33 or input[0]<1 or input[0]>32) return -1;
    const n: usize=@intCast(input[0]);
    if (length!=n+1) return -1;
    for (0..n) |i| { if (input[1+i]<0 or input[1+i]>=modulus) return -1; }
    if (output==null or capacity<8*(n+1)) return -2;
    var choose: [33][33]i64=@splat(@splat(0));
    var inverse: [33]i64=@splat(0); var g: [33]i64=@splat(0);
    choose[0][0]=1;
    for (1..n+1) |k| {
        choose[k][0]=1; choose[k][k]=1;
        for (1..k) |j| choose[k][j]=@mod(choose[k-1][j-1]+choose[k-1][j],modulus);
    }
    inverse[1]=1;
    for (2..n+1) |k| {
        const kk: i64=@intCast(k);
        inverse[k]=modulus-@mod(@divTrunc(modulus,kk)*inverse[@intCast(@mod(modulus,kk))],modulus);
    }
    var j=n;
    while (j>0) {
        j-=1; var sum: i64=0;
        for (j+2..n+1) |k| sum=@mod(sum+choose[k][j]*g[k],modulus);
        g[j+1]=@mod(@mod(input[1+j]-sum+modulus,modulus)*inverse[j+1],modulus);
    }
    for (0..n+1) |i| {
        const bits: u64=@intCast(g[i]);
        for (0..8) |byte| output[8*i+byte]=@truncate(bits >> @as(u6,@intCast(8*byte)));
    }
    return @intCast(8*(n+1));
}
