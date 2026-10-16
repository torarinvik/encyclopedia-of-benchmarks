fn writeRun(output: [*]u8, position_input: usize, byte: u8, count: usize) usize {
    var position = position_input;
    for (0..count) |_| {
        output[position] = byte;
        position += 1;
    }
    return position;
}

pub export fn butterfly_pattern(n: i64, output: [*c]u8, capacity: usize) i64 {
    if (n < 1 or n > 45) return -1;
    const side: usize = @intCast(n);
    const width = 2 * side - 1;
    const required = width * width + 2 * side - 2;
    if (output == null or capacity < required) return -2;
    const out: [*]u8 = @ptrCast(output);

    var position: usize = 0;
    for (1..side) |count| {
        if (position != 0) { out[position] = '\n'; position += 1; }
        position = writeRun(out, position, '*', count);
        position = writeRun(out, position, ' ', 2 * (side - count) - 1);
        position = writeRun(out, position, '*', count);
    }
    if (position != 0) { out[position] = '\n'; position += 1; }
    position = writeRun(out, position, '*', width);
    var count = side - 1;
    while (count > 0) : (count -= 1) {
        out[position] = '\n'; position += 1;
        position = writeRun(out, position, '*', count);
        position = writeRun(out, position, ' ', 2 * (side - count) - 1);
        position = writeRun(out, position, '*', count);
    }
    return @intCast(position);
}
