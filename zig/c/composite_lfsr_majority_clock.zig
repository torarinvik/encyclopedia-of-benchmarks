/// One majority-clock step for the three source-configured A5 LFSRs.
fn writeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn composite_lfsr_majority_clock(input: ?[*]const i64, length: usize,
        output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length != 3) return -1;
    const values = input.?[0..3];
    if (values[0] < 0 or values[0] > 524287 or values[1] < 0 or values[1] > 4194303 or values[2] < 0 or values[2] > 8388607) return -1;
    if (output == null or output_capacity < 32) return -2;
    var s1: u64 = @intCast(values[0]); var s2: u64 = @intCast(values[1]); var s3: u64 = @intCast(values[2]);
    const c1 = (s1 >> 8) & 1; const c2 = (s2 >> 10) & 1; const c3 = (s3 >> 10) & 1;
    const majority = c1 + c2 + c3 >= 2;
    const emitted = ((s1 >> 18) ^ (s2 >> 21) ^ (s3 >> 22)) & 1;
    if ((c1 == 1) == majority) s1 = ((s1 << 1) & 524287) | (((s1 >> 13) ^ (s1 >> 16) ^ (s1 >> 17) ^ (s1 >> 18)) & 1);
    if ((c2 == 1) == majority) s2 = ((s2 << 1) & 4194303) | (((s2 >> 20) ^ (s2 >> 21)) & 1);
    if ((c3 == 1) == majority) s3 = ((s3 << 1) & 8388607) | (((s3 >> 7) ^ (s3 >> 20) ^ (s3 >> 21) ^ (s3 >> 22)) & 1);
    const out = output.?;
    writeI64Le(out, 0, @intCast(emitted)); writeI64Le(out, 8, @intCast(s1));
    writeI64Le(out, 16, @intCast(s2)); writeI64Le(out, 24, @intCast(s3));
    return 32;
}
