const ANGLES = [_]i64{
    785398163, 463647609, 244978663, 124354995, 62418810,
    31239833, 15623729, 7812341, 3906230, 1953123,
    976562, 488281, 244141, 122070, 61035,
};
const OUTPUT_BYTES: usize = 24;

fn shiftFloor(value: i64, shift: u6) i64 {
    if (shift == 0) return value;
    const divisor: i64 = @as(i64, 1) << shift;
    if (value >= 0) return @divTrunc(value, divisor);
    return -@divTrunc(-value + divisor - 1, divisor);
}

fn putF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn cordic_rotation_fixed_point(
    values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize,
) i64 {
    if (values == null or length < 2 or length > 3) return -1;
    if (length != 2) return -1;
    const angle = values[0];
    const stages = values[1];
    if (angle < -3_141_592_653 or angle > 3_141_592_653 or stages < 1 or stages > 16) return -1;
    if (output == null or capacity < OUTPUT_BYTES) return -2;

    var x: i64 = 1_000_000_000;
    var y: i64 = 0;
    var z: i64 = angle;
    var direction: i64 = if (z >= 0) 1 else -1;
    if (direction > 0) {
        const old_x = x;
        x = -y;
        y = old_x;
    } else {
        const old_x = x;
        x = y;
        y = -old_x;
    }
    z -= direction * 1_570_796_327;
    var shift: usize = 0;
    while (shift < @as(usize, @intCast(stages - 1))) : (shift += 1) {
        direction = if (z >= 0) 1 else -1;
        const old_x = x;
        const old_y = y;
        x = old_x - direction * shiftFloor(old_y, @intCast(shift));
        y = old_y + direction * shiftFloor(old_x, @intCast(shift));
        z -= direction * ANGLES[shift];
    }

    var staged: [OUTPUT_BYTES]u8 = undefined;
    putF64Le(&staged, 0, @as(f64, @floatFromInt(x)) / 1_000_000_000.0);
    putF64Le(&staged, 8, @as(f64, @floatFromInt(y)) / 1_000_000_000.0);
    putF64Le(&staged, 16, @as(f64, @floatFromInt(z)) / 1_000_000_000.0);
    for (0..OUTPUT_BYTES) |byte| output[byte] = staged[byte];
    return OUTPUT_BYTES;
}
