fn gcd(a0: u64, b0: u64) u64 {
    var a = a0;
    var b = b0;
    while (b != 0) { const r = a % b; a = b; b = r; }
    return a;
}

export fn hyperloglog_raw_estimate(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > 130) return -1;
    const input = input_opt.?;
    const raw = input[0];
    if (raw < 0 or raw > 128) return -1;
    const n: usize = @intCast(raw);
    if (length != n+1) return -1;
    var registers: [16]u8 = @splat(0);
    for (0..n) |i| {
        const value = input[i+1];
        if (value < 0 or value > 4294967295) return -1;
        const hash: u32 = @intCast(value);
        const bucket: usize = @intCast(hash >> 28);
        const suffix = hash & 0x0fffffff;
        const rank: u8 = @intCast(@clz(suffix) - 3);
        if (rank > registers[bucket]) registers[bucket] = rank;
    }
    var sum: u64 = 0;
    for (registers) |rank| sum += @as(u64,1) << @intCast(29-rank);
    var numerator: u64 = 673*256*(@as(u64,1)<<29);
    var denominator: u64 = 1000*sum;
    const factor = gcd(numerator,denominator);
    numerator /= factor; denominator /= factor;
    if (output_opt == null or capacity < 144) return -2;
    var words: [18]u64 = @splat(0);
    words[0] = numerator; words[1] = denominator;
    for (0..16) |i| words[i+2] = registers[i];
    var staged: [144]u8 = @splat(0);
    for (0..18) |i| {
        for (0..8) |b| staged[8*i+b] = @truncate(words[i] >> @intCast(8*b));
    }
    const output = output_opt.?;
    for (0..144) |i| output[i] = staged[i];
    return 144;
}
