const coordinate_limit: i64 = 1_000_000;
const max_step: i64 = 4096;

fn pointCount(x0: i64, y0: i64, x1: i64, y1: i64) usize {
    var x = x0;
    var y = y0;
    const dx: i64 = @intCast(@abs(x1 - x0));
    const distance_y: i64 = @intCast(@abs(y1 - y0));
    const dy: i64 = -distance_y;
    const sx: i64 = if (x0 < x1) 1 else -1;
    const sy: i64 = if (y0 < y1) 1 else -1;
    var err = dx + dy;
    var count: usize = 0;
    while (true) {
        count += 1;
        if (x == x1 and y == y1) break;
        const e2 = 2 * err;
        if (e2 >= dy) {
            err += dy;
            x += sx;
        }
        if (e2 <= dx) {
            err += dx;
            y += sy;
        }
    }
    return count;
}

fn writeI32(output: [*c]u8, position: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| output[position * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn writePoint(output: [*c]u8, position: usize, x: i64, y: i64) void {
    writeI32(output, 2 * position, x);
    writeI32(output, 2 * position + 1, y);
}

fn rasterize(output: [*c]u8, x0: i64, y0: i64, x1: i64, y1: i64) void {
    var x = x0;
    var y = y0;
    const dx: i64 = @intCast(@abs(x1 - x0));
    const distance_y: i64 = @intCast(@abs(y1 - y0));
    const dy: i64 = -distance_y;
    const sx: i64 = if (x0 < x1) 1 else -1;
    const sy: i64 = if (y0 < y1) 1 else -1;
    var err = dx + dy;
    var count: usize = 0;
    while (true) {
        writePoint(output, count, x, y);
        count += 1;
        if (x == x1 and y == y1) break;
        const e2 = 2 * err;
        if (e2 >= dy) {
            err += dy;
            x += sx;
        }
        if (e2 <= dx) {
            err += dx;
            y += sy;
        }
    }
}

// Rasterize an inclusive integer line with the source algorithm's inclusive error tests.
export fn bresenhams_line(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 4) return -1;
    const x0 = values[0];
    const y0 = values[1];
    const x1 = values[2];
    const y1 = values[3];
    if (x0 < -coordinate_limit or x0 > coordinate_limit or y0 < -coordinate_limit or y0 > coordinate_limit or
        x1 < -coordinate_limit or x1 > coordinate_limit or y1 < -coordinate_limit or y1 > coordinate_limit or
        x1 - x0 < -max_step or x1 - x0 > max_step or y1 - y0 < -max_step or y1 - y0 > max_step) return -1;
    const byte_count = pointCount(x0, y0, x1, y1) * 8;
    if (output == null or output_capacity < byte_count) return -2;
    rasterize(output, x0, y0, x1, y1);
    return @intCast(byte_count);
}
