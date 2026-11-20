const MAX_WORDS: usize = 257;
const MAX_PAYLOAD: i64 = 255;
const MAX_OUTPUT: usize = 257;

export fn consistent_overhead_byte_stuffing(
    raw_input: ?[*]const i64,
    length: usize,
    raw_output: ?[*]u8,
    capacity: usize,
) i64 {
    const input = raw_input orelse return -1;
    if (length < 1 or length > MAX_WORDS) return -1;
    if (input[0] < 0 or input[0] > MAX_PAYLOAD) return -1;
    const payload_length: usize = @intCast(input[0]);
    if (length != payload_length + 1) return -1;
    for (0..payload_length) |index| {
        if (input[index + 1] < 0 or input[index + 1] > 255) return -1;
    }

    var staged = [_]u8{0} ** MAX_OUTPUT;
    var written: usize = 1;
    var code_position: usize = 0;
    var code: u16 = 1;
    var omitted_terminal_code = false;
    for (0..payload_length) |index| {
        const byte: u8 = @intCast(input[index + 1]);
        if (byte == 0) {
            staged[code_position] = @intCast(code);
            code_position = written;
            written += 1;
            code = 1;
        } else {
            staged[written] = byte;
            written += 1;
            code += 1;
            if (code == 255) {
                staged[code_position] = 255;
                if (index + 1 == payload_length) {
                    omitted_terminal_code = true;
                    break;
                }
                code_position = written;
                written += 1;
                code = 1;
            }
        }
    }
    if (!omitted_terminal_code) staged[code_position] = @intCast(code);
    const destination = raw_output orelse return -2;
    if (capacity < written) return -2;
    @memcpy(destination[0..written], staged[0..written]);
    return @intCast(written);
}
