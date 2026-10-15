/// Minimum time to cross two assembly lines using station-by-station dynamic programming.
export fn assembly_line_scheduling(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 7 or values[0] < 1 or values[0] > 64) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 4 * n + 3) return -1;
    for (0..length) |index| {
        if (values[index] < 0 or values[index] > 1000) return -1;
    }

    const a0 = 1;
    const a1 = a0 + n;
    const t0 = a1 + n;
    const t1 = t0 + n - 1;
    const entry = t1 + n - 1;
    var line0 = values[entry] + values[a0];
    var line1 = values[entry + 1] + values[a1];
    for (1..n) |station| {
        const stay0 = line0 + values[a0 + station];
        const switch0 = line1 + values[t1 + station - 1] + values[a0 + station];
        const stay1 = line1 + values[a1 + station];
        const switch1 = line0 + values[t0 + station - 1] + values[a1 + station];
        line0 = @min(stay0, switch0);
        line1 = @min(stay1, switch1);
    }
    const total0 = line0 + values[entry + 2];
    const total1 = line1 + values[entry + 3];
    const answer = @min(total0, total1);
    if (output_capacity < 4) return -2;
    const bits: u32 = @intCast(answer);
    for (0..4) |byte| {
        output[byte] = @truncate(bits >> @intCast(8 * byte));
    }
    return 4;
}
