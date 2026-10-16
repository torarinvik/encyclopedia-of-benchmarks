/// Two-sided CUSUM detector over a bounded integer-valued input domain.
fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[offset+b] = @truncate(bits >> @intCast(8*b));
}
pub export fn cusum_detector(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 5 or input[0] < 0 or input[0] > 128) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n+5) return -1;
    const packed=input[0..length];
    const target=packed[1]; const sigma=packed[2]; const allowance=packed[3]; const threshold=packed[4];
    if (target < -1000 or target > 1000 or sigma < 1 or sigma > 1000 or allowance < 0 or allowance > 1000 or threshold < 1 or threshold > 1000) return -1;
    for (packed[5..]) |v| { if (v < -1000 or v > 1000) return -1; }
    if (capacity<n*8 or (n>0 and output==null)) return -2;
    var upper:f64=0; var lower:f64=0;
    for (packed[5..],0..) |sample,i| {
        const z=(@as(f64,@floatFromInt(sample)) - @as(f64,@floatFromInt(target))) / @as(f64,@floatFromInt(sigma));
        upper=@max(0.0,upper+z-@as(f64,@floatFromInt(allowance)));
        lower=@max(0.0,lower-z-@as(f64,@floatFromInt(allowance)));
        var signal:i64=0;
        if (upper>@as(f64,@floatFromInt(threshold))) signal=1 else if (lower>@as(f64,@floatFromInt(threshold))) signal=-1;
        if (signal!=0) { upper=0; lower=0; }
        putI64Le(output,i*8,signal);
    }
    return @intCast(n*8);
}
