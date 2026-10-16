const limit: i64 = 1_000_000;

fn writeF64Le(output: [*c]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn cramers_rule_2x2(v: [*c]const i64, length: usize,
                           output: [*c]u8, capacity: usize) i64 {
    if (v == null or length != 6) return -1;
    for (0..6) |i| if (v[i] < -limit or v[i] > limit) return -1;
    const a1=v[0]; const b1=v[1]; const c1=v[2];
    const a2=v[3]; const b2=v[4]; const c2=v[5];
    const d=a1*b2-a2*b1; const dx=c1*b2-c2*b1; const dy=a1*c2-a2*c1;
    if (d == 0) return -1;
    if (output == null or capacity < 16) return -2;
    writeF64Le(output, 0, @as(f64, @floatFromInt(dx)) / @as(f64, @floatFromInt(d)));
    writeF64Le(output, 8, @as(f64, @floatFromInt(dy)) / @as(f64, @floatFromInt(d)));
    return 2;
}
