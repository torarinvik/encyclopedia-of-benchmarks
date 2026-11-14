const modulus: i64 = 998244353;
fn power(base_input: i64, exponent_input: i64) i64 {
    var base=base_input; var exponent=exponent_input; var result: i64=1;
    while (exponent>0) {
        if (exponent & 1 != 0) result=@mod(result*base,modulus);
        base=@mod(base*base,modulus); exponent >>= 1;
    }
    return result;
}
fn locate(q: *const [15]usize, count: usize, value: usize) ?usize {
    var lo: usize=0; var hi=count;
    while (lo<hi) {
        const mid=lo+(hi-lo)/2;
        if (q[mid]<value) lo=mid+1 else hi=mid;
    }
    if (lo<count and q[lo]==value) return lo;
    return null;
}
pub export fn dirichlet_inverse_and_prefix_sums(input: [*c]const i64, length: usize,
                                                 output: [*c]u8, capacity: usize) i64 {
    if (input==null or length<2 or length>16 or input[0]<1 or input[0]>64) return -1;
    const n: usize=@intCast(input[0]);
    var q: [15]usize=@splat(0); var count: usize=0; var i=n;
    while (i>0) : (i-=1) {
        const value=n/i;
        if (count==0 or q[count-1]!=value) { q[count]=value; count+=1; }
    }
    if (length!=1+count or input[1]==0) return -1;
    for (0..count) |j| { if (input[1+j]<0 or input[1+j]>=modulus) return -1; }
    if (output==null or capacity<8*count) return -2;
    const inverse=power(input[1],modulus-2);
    var g: [15]i64=@splat(0);
    for (0..count) |j| {
        const x=q[j]; var left: usize=2; var total: i64=0;
        while (left<=x) {
            const quotient=x/left; const right=x/quotient;
            const hi=locate(&q,count,right) orelse return -1;
            const lo=locate(&q,count,left-1) orelse return -1;
            const gi=locate(&q,count,quotient) orelse return -1;
            const interval=@mod(input[1+hi]-input[1+lo]+modulus,modulus);
            total=@mod(total+interval*g[gi],modulus);
            left=right+1;
        }
        g[j]=@mod(@mod(1-total+modulus,modulus)*inverse,modulus);
    }
    for (0..count) |j| {
        const bits: u64=@intCast(g[j]);
        for (0..8) |byte| output[8*j+byte]=@truncate(bits >> @as(u6,@intCast(8*byte)));
    }
    return @intCast(8*count);
}
