/// Emit a bounded geometric term sequence as little-endian binary64 values.
fn putF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}
pub export fn geometric_series(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 3) return -1;
    if (input[0] < 0 or input[0] > 16 or input[1] < 1 or input[1] > 8 or input[2] < 1 or input[2] > 4) return -1;
    const n: usize = @intCast(input[0]);
    if (capacity < n * 8 or (n > 0 and output == null)) return -2;
    var term: f64 = @floatFromInt(input[1]); const ratio: f64 = @floatFromInt(input[2]);
    for (0..n) |index| { putF64Le(output, index * 8, term); term *= ratio; }
    return @intCast(n * 8);
}
