const MAX_JOBS: usize = 32;
const QUANTUM: i64 = 2;

fn putI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn round_robin(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1) return -1;
    const values = input.?[0..length];
    const raw_count = values[0];
    if (raw_count < 0 or raw_count > MAX_JOBS or length != @as(usize, @intCast(raw_count)) + 1) return -1;
    const count: usize = @intCast(raw_count);
    const bursts = values[1..];
    for (bursts) |burst| if (burst < 0 or burst > 4096) return -1;
    const bytes = (1 + 2 * count) * 8;
    if (output == null or capacity < bytes) return -2;
    var remaining: [MAX_JOBS]i64 = @splat(0);
    var waiting: [MAX_JOBS]i64 = @splat(0);
    @memcpy(remaining[0..count], bursts);
    var elapsed: i64 = 0;
    while (true) {
        var done = true;
        for (0..count) |i| {
            if (remaining[i] > 0) {
                done = false;
                if (remaining[i] > QUANTUM) {
                    elapsed += QUANTUM;
                    remaining[i] -= QUANTUM;
                } else {
                    elapsed += remaining[i];
                    waiting[i] = elapsed - bursts[i];
                    remaining[i] = 0;
                }
            }
        }
        if (done) break;
    }
    const result = output.?[0..bytes];
    putI64Le(result, 0, raw_count);
    for (0..count) |i| putI64Le(result, 8 * (1 + i), waiting[i]);
    for (0..count) |i| putI64Le(result, 8 * (1 + count + i), bursts[i] + waiting[i]);
    return @intCast(bytes);
}
