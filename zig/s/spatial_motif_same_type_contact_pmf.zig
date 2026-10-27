const MAX_LENGTH: usize = 16;
const MAX_SUPPORT: usize = 17;

fn chooseValue(n: usize, k0: usize) i64 {
    if (k0 > n) return 0;
    const k = @min(k0, n-k0);
    var result: i64 = 1;
    var i: usize = 1;
    while (i <= k) : (i += 1) result = result * @as(i64,@intCast(n-k+i)) / @as(i64,@intCast(i));
    return result;
}
fn gcdValue(a0: i64, b0: i64) i64 {
    var a=a0;var b=b0;
    while (b!=0) { const r=@rem(a,b);a=b;b=r; }
    return a;
}
fn putI64(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word*8+byte]=@truncate(bits >> @intCast(byte*8));
}

export fn spatial_motif_same_type_contact_pmf(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if(input==null||length!=3)return -1;
    const l0=input[0];const x10=input[1];const x20=input[2];
    if(l0<1||l0>MAX_LENGTH||x10<0||x10>l0||x20<0||x20>l0)return -1;
    const l:usize=@intCast(l0);const x1:usize=@intCast(x10);const x2:usize=@intCast(x20);
    const low=if(x1+x2>l)x1+x2-l else 0;const high=@min(x1,x2);
    const denominator=chooseValue(l,x2);
    var numerators=[_]i64{0} ** MAX_SUPPORT;
    var i=low;while(i<=high):(i+=1) numerators[i-low]=chooseValue(x1,i)*chooseValue(l-x1,x2-i);
    var expected_num=@as(i64,@intCast(x1*x2));var expected_den=@as(i64,@intCast(l));
    const divisor=gcdValue(expected_num,expected_den);expected_num=@divTrunc(expected_num,divisor);expected_den=@divTrunc(expected_den,divisor);
    const count=high-low+1;const bytes=(3+count+2)*8;
    if(output==null||capacity<bytes)return -2;
    putI64(output,0,@intCast(low));putI64(output,1,@intCast(high));putI64(output,2,denominator);
    for(0..count)|idx|putI64(output,3+idx,numerators[idx]);
    putI64(output,3+count,expected_num);putI64(output,4+count,expected_den);
    return @intCast(bytes);
}
