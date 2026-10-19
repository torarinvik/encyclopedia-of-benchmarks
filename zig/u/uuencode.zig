const MAX_INPUT_BYTES: usize = 4096;
const HEADER = "begin 640 uuencode.c \n";
const TRAILER = " \nend";

fn symbol(value: u32) u8 {
    return @intCast(32 + (value & 63));
}

export fn uuencode(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length > MAX_INPUT_BYTES) return -1;
    const input = input_opt.?;
    for (0..length) |i| {
        if (input[i] < 0 or input[i] > 255) return -1;
    }
    const needed = HEADER.len + 4 * ((length + 2) / 3) +
        2 * ((length + 44) / 45) + TRAILER.len;
    if (output_opt == null or capacity < needed) return -2;
    const output = output_opt.?;
    var cursor: usize = 0;
    @memcpy(output[0..HEADER.len], HEADER);
    cursor += HEADER.len;
    var start: usize = 0;
    while (start < length) {
        const remaining = length - start;
        const line_len = if (remaining < 45) remaining else 45;
        const stop = start + line_len;
        output[cursor] = symbol(@intCast(line_len));
        cursor += 1;
        var index = start;
        while (index < stop) : (index += 3) {
            const a: u32 = @intCast(input[index]);
            const has_b = index + 1 < stop;
            const has_c = index + 2 < stop;
            const b: u32 = if (has_b) @intCast(input[index + 1]) else 0;
            const c: u32 = if (has_c) @intCast(input[index + 2]) else 0;
            output[cursor] = symbol(a >> 2); cursor += 1;
            output[cursor] = symbol((a << 4) | (b >> 4)); cursor += 1;
            output[cursor] = if (has_b) symbol((b << 2) | (c >> 6)) else '='; cursor += 1;
            output[cursor] = if (has_c) symbol(c) else '='; cursor += 1;
        }
        output[cursor] = '\n'; cursor += 1;
        start = stop;
    }
    @memcpy(output[cursor..][0..TRAILER.len], TRAILER);
    cursor += TRAILER.len;
    return @intCast(cursor);
}
