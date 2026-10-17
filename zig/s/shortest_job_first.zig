const MAX_JOBS: usize = 32;
const SENTINEL: i64 = 999_999_999;

fn putI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn shortest_job_first(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1) return -1;
    const values = input.?[0..length];
    const raw_count = values[0];
    if (raw_count < 0 or raw_count > MAX_JOBS or length != 1 + 2 * @as(usize, @intCast(raw_count))) return -1;
    const count: usize = @intCast(raw_count);
    const arrivals = values[1..1 + count];
    const bursts = values[1 + count ..];
    for (arrivals) |arrival| if (arrival < 0 or arrival > 64) return -1;
    for (bursts) |burst| if (burst < 1 or burst > 128 or burst >= SENTINEL) return -1;
    const bytes = (1 + 2 * count) * 8;
    if (output == null or capacity < bytes) return -2;
    var remaining: [MAX_JOBS]i64 = @splat(0);
    var waiting: [MAX_JOBS]i64 = @splat(0);
    @memcpy(remaining[0..count], bursts);
    var complete: usize = 0;
    var time: i64 = 0;
    var minimum: i64 = SENTINEL;
    var short_index: usize = 0;
    var check = false;
    while (complete != count) {
        for (0..count) |j| {
            if (arrivals[j] <= time and remaining[j] > 0 and remaining[j] < minimum) {
                minimum = remaining[j];
                short_index = j;
                check = true;
            }
        }
        if (!check) { time += 1; continue; }
        remaining[short_index] -= 1;
        minimum = remaining[short_index];
        if (minimum == 0) minimum = SENTINEL;
        if (remaining[short_index] == 0) {
            complete += 1;
            check = false;
            const wait = time + 1 - arrivals[short_index] - bursts[short_index];
            waiting[short_index] = if (wait > 0) wait else 0;
        }
        time += 1;
    }
    const result = output.?[0..bytes];
    putI64Le(result, 0, raw_count);
    for (0..count) |i| putI64Le(result, 8 * (1 + i), waiting[i]);
    for (0..count) |i| putI64Le(result, 8 * (1 + count + i), bursts[i] + waiting[i]);
    return @intCast(bytes);
}
