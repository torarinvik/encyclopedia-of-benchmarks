pub export fn discrete_logarithm_fixed_mod(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input==null or length<3 or length>259) return -1;
    if (input[0]<2 or input[0]>4093 or input[1]<1 or input[1]>=input[0] or input[2]<1 or input[2]>256) return -1;
    const p:usize=@intCast(input[0]); const g:usize=@intCast(input[1]); const n:usize=@intCast(input[2]);
    if (length!=n+3) return -1;
    var d:usize=2;
    while (d*d<=p) : (d+=1) { if (p%d==0) return -1; }
    for (0..n) |i| { if (input[3+i]<1 or input[3+i]>=input[0]) return -1; }
    var table:[4094]i16=@splat(-1);
    var residue:usize=1;
    for (0..p-1) |exponent| {
        if (table[residue]!=-1) return -1;
        table[residue]=@intCast(exponent);
        residue=residue*g%p;
    }
    if (residue!=1) return -1;
    if (output==null or capacity<8*n) return -2;
    for (0..n) |i| {
        const target:usize=@intCast(input[3+i]);
        const value:u64=@intCast(table[target]);
        for (0..8) |byte| output[8*i+byte]=@truncate(value >> @as(u6,@intCast(8*byte)));
    }
    return @intCast(8*n);
}
