const MAX_COUNT: usize = 1024;
const REGISTER_COUNT: usize = 65_536;

export fn hyper_log_log(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 2 or length > MAX_COUNT + 1) return -1;
    const count64 = values[0];
    if (count64 < 1 or count64 > MAX_COUNT or length != @as(usize, @intCast(count64)) + 1) return -1;
    const count: usize = @intCast(count64);
    for (0..count) |i| if (values[1 + i] < 1 or values[1 + i] > 65_535) return -1;

    var registers = [_]u8{0} ** REGISTER_COUNT;
    var seen = [_]u8{0} ** REGISTER_COUNT;
    var touched = [_]u16{0} ** MAX_COUNT;
    var touched_count: usize = 0;
    for (0..count) |i| {
        const value: u32 = @intCast(values[1 + i]);
        const index: usize = @intCast(value);
        const rank: u8 = @intCast(@ctz(value));
        if (seen[index] == 0) { seen[index] = 1; touched[touched_count] = @intCast(value); touched_count += 1; }
        if (rank > registers[index]) registers[index] = rank;
    }

    var z: f64 = 0.0;
    for (0..touched_count) |i| {
        const index: usize = @intCast(touched[i]);
        z += 1.0 / @as(f64, @floatFromInt(@as(u32, 1) << registers[index]));
    }
    const k: f64 = @floatFromInt(touched_count);
    return @intFromFloat(@ceil(0.673 * k * (k / z)));
}
