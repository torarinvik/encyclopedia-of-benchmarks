const max_n: usize = 16;
const max_input: usize = 50;

fn power(base: i64, exponent: i64) i64 {
    var result: i64 = 1;
    var i: i64 = 0;
    while (i < exponent) : (i += 1) result *= base;
    return result;
}
fn put64(out: [*]u8, pos: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |j| out[pos+j] = @truncate(bits >> @intCast(8*j));
}

export fn weighted_random_sampling(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > max_input) return -1;
    const input=input_opt.?; const n64=input[0]; const m64=input[1];
    if (n64<1 or n64>16 or m64<1 or m64>n64 or length!=2+3*@as(usize,@intCast(n64))) return -1;
    const n:usize=@intCast(n64); const m:usize=@intCast(m64);
    var weights:[max_n]i64=@splat(0); var nums:[max_n]i64=@splat(0); var dens:[max_n]i64=@splat(0);
    for (0..n) |i| {
        weights[i]=input[2+3*i]; nums[i]=input[3+3*i]; dens[i]=input[4+3*i];
        if (weights[i]<1 or weights[i]>3 or nums[i]<1 or nums[i]>=dens[i] or dens[i]>100) return -1;
    }
    const bytes=8*m;
    if (output_opt==null or capacity<bytes) return -2;
    const output=output_opt.?; var available:[max_n]i64=@splat(0); var chosen:[max_n]i64=@splat(0);
    for (0..n) |i| available[i]=@intCast(i);
    for (0..m) |rank| {
        var best:usize=0;
        for (1..n-rank) |i| {
            const left:usize=@intCast(available[i]); const right:usize=@intCast(available[best]);
            const lhs=power(nums[left],weights[right])*power(dens[right],weights[left]);
            const rhs=power(nums[right],weights[left])*power(dens[left],weights[right]);
            if (lhs>rhs or (lhs==rhs and left<right)) best=i;
        }
        chosen[rank]=available[best];
        var i=best;
        while (i+1<n-rank) : (i+=1) available[i]=available[i+1];
    }
    for (0..m) |i| put64(output,8*i,chosen[i]);
    return @intCast(bytes);
}
