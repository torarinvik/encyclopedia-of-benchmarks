export fn hyperloglog_corrected_estimate(input_opt: ?[*]const i64, length: usize,
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
        const rank: u8 = @intCast(@clz(hash & 0x0fffffff) - 3);
        if (rank > registers[bucket]) registers[bucket] = rank;
    }
    var sum: u64 = 0;
    var zeros: usize = 0;
    for (registers) |rank| {
        sum += @as(u64,1) << @intCast(29-rank);
        if (rank == 0) zeros += 1;
    }
    var estimate: f64 = (673.0*256.0*536870912.0)/(1000.0*@as(f64,@floatFromInt(sum)));
    const universe: f64 = 4294967296.0;
    if (estimate <= 40.0 and zeros != 0) {
        estimate = 16.0*@log(16.0/@as(f64,@floatFromInt(zeros)));
    } else if (estimate > universe/30.0) {
        if (estimate >= universe) return -3;
        estimate = -universe*@log(1.0-estimate/universe);
    }
    if (output_opt == null or capacity < 8) return -2;
    const bits: u64 = @bitCast(estimate);
    var staged: [8]u8 = @splat(0);
    for (0..8) |b| staged[b] = @truncate(bits >> @intCast(8*b));
    const output = output_opt.?;
    for (0..8) |b| output[b] = staged[b];
    return 8;
}
