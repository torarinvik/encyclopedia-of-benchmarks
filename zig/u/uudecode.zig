const MAX_INPUT_BYTES: usize = 4096;
const MAX_OUTPUT_BYTES: usize = 2949;
const HEADER = "begin 755 uustart.file \n";

fn scan(input: [*]const i64, length: usize) ?usize {
    if (length > MAX_INPUT_BYTES) return null;
    for (0..length) |i| {
        if (input[i] < 0 or input[i] > 255) return null;
    }
    if (length < HEADER.len + 5) return null;
    for (0..HEADER.len) |i| {
        if (input[i] != @as(i64, HEADER[i])) return null;
    }

    var cursor: usize = HEADER.len;
    var total: usize = 0;
    while (cursor < length) {
        const marker: usize = @intCast(input[cursor]);
        cursor += 1;
        if (marker == 32) {
            if (cursor + 4 != length or input[cursor] != 10 or input[cursor + 1] != 'e' or
                input[cursor + 2] != 'n' or input[cursor + 3] != 'd') return null;
            if (total > MAX_OUTPUT_BYTES) return null;
            return total;
        }
        if (marker < 33 or marker > 77) return null;
        const count = marker - 32;
        const encoded = 4 * ((count + 2) / 3);
        if (cursor + encoded >= length or input[cursor + encoded] != 10) return null;
        for (0..encoded) |i| {
            if (input[cursor + i] < 32 or input[cursor + i] > 95) return null;
        }
        total += count;
        if (total > MAX_OUTPUT_BYTES) return null;
        cursor += encoded + 1;
    }
    return null;
}

export fn uudecode(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length > MAX_INPUT_BYTES) return -1;
    const input = input_opt.?;
    const decoded_length = scan(input, length) orelse return -1;
    if (output_opt == null or capacity < decoded_length) return -2;
    const output = output_opt.?;

    var cursor: usize = HEADER.len;
    var written: usize = 0;
    while (true) {
        const count: usize = @intCast(input[cursor] - 32);
        cursor += 1;
        if (count == 0) break;
        const encoded = 4 * ((count + 2) / 3);
        var emitted: usize = 0;
        var group: usize = 0;
        while (group < encoded) : (group += 4) {
            const a: u32 = @intCast(input[cursor] - 32);
            const b: u32 = @intCast(input[cursor + 1] - 32);
            const c: u32 = @intCast(input[cursor + 2] - 32);
            const d: u32 = @intCast(input[cursor + 3] - 32);
            cursor += 4;
            output[written] = @intCast(((a << 2) | (b >> 4)) & 255);
            written += 1;
            emitted += 1;
            if (emitted < count) {
                output[written] = @intCast(((b << 4) | (c >> 2)) & 255);
                written += 1;
                emitted += 1;
            }
            if (emitted < count) {
                output[written] = @intCast(((c << 6) | d) & 255);
                written += 1;
                emitted += 1;
            }
        }
        cursor += 1;
    }
    return @intCast(written);
}
