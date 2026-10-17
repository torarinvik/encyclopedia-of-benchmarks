const INVALID_RESULT: i64 = -1;
const MAX_OUTPUT_BYTES: usize = 11616;

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn emitSegment(output: []u8, position: *usize, x0: i64, y0: i64, x1: i64, y1: i64) void {
    writeI64Le(output, position.*, x0); position.* += 8;
    writeI64Le(output, position.*, y0); position.* += 8;
    writeI64Le(output, position.*, x1); position.* += 8;
    writeI64Le(output, position.*, y1); position.* += 8;
}

fn drawTriangle(output: []u8, position: *usize,
    x1: i64, y1: i64, x2: i64, y2: i64, x3: i64, y3: i64, depth: i64) void {
    emitSegment(output, position, x1, y1, x2, y2);
    emitSegment(output, position, x2, y2, x3, y3);
    emitSegment(output, position, x3, y3, x1, y1);
    if (depth == 0) return;
    const abx = @divTrunc(x1 + x2, 2);
    const aby = @divTrunc(y1 + y2, 2);
    const acx = @divTrunc(x1 + x3, 2);
    const acy = @divTrunc(y1 + y3, 2);
    const bcx = @divTrunc(x2 + x3, 2);
    const bcy = @divTrunc(y2 + y3, 2);
    drawTriangle(output, position, x1, y1, abx, aby, acx, acy, depth - 1);
    drawTriangle(output, position, x2, y2, abx, aby, bcx, bcy, depth - 1);
    drawTriangle(output, position, x3, y3, bcx, bcy, acx, acy, depth - 1);
}

export fn sierpinski_triangle(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length != 1) return INVALID_RESULT;
    const depth = input.?[0];
    if (depth < 0 or depth > 4) return INVALID_RESULT;
    var calls: usize = 1;
    var level: i64 = 0;
    while (level < depth) : (level += 1) calls = calls * 3 + 1;
    const needed = calls * 96;
    if (needed > MAX_OUTPUT_BYTES) return INVALID_RESULT;
    if (output == null or capacity < needed) return -2;
    const result = output.?[0..needed];
    var position: usize = 0;
    drawTriangle(result, &position, -2800, -2000, 0, 2800, 2800, -2000, depth);
    return @intCast(needed);
}
