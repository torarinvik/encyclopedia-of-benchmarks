const MAX_PAYLOAD_BYTES: usize = 256;
const MAX_INPUT_LENGTH: usize = 259;
const OUTPUT_BYTES: usize = 16;

fn utf8ScalarCount(bytes: []const u8) i64 {
    var index: usize = 0;
    var count: i64 = 0;
    while (index < bytes.len) {
        const lead = bytes[index];
        if (lead >= 1 and lead <= 0x7f) {
            index += 1;
        } else if (lead >= 0xc2 and lead <= 0xdf) {
            if (index + 1 >= bytes.len or bytes[index + 1] < 0x80 or bytes[index + 1] > 0xbf) return -1;
            index += 2;
        } else if (lead >= 0xe0 and lead <= 0xef) {
            if (index + 2 >= bytes.len) return -1;
            const second = bytes[index + 1];
            const third = bytes[index + 2];
            if (second < 0x80 or second > 0xbf or third < 0x80 or third > 0xbf or
                (lead == 0xe0 and second < 0xa0) or (lead == 0xed and second > 0x9f)) return -1;
            index += 3;
        } else {
            return -1;
        }
        count += 1;
    }
    return count;
}

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn length(input: [*c]const i64, input_length: usize,
                 output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_INPUT_LENGTH) return -1;
    const values = input;
    if (values[0] < 0 or values[0] > MAX_PAYLOAD_BYTES) return -1;
    const payload_length: usize = @intCast(values[0]);
    if (input_length != payload_length + 2) return -1;

    var payload: [MAX_PAYLOAD_BYTES]u8 = [_]u8{0} ** MAX_PAYLOAD_BYTES;
    for (0..payload_length + 1) |index| {
        const value = values[index + 1];
        if (value < 0 or value > 255) return -1;
        if (index == payload_length) {
            if (value != 0) return -1;
        } else {
            if (value == 0) return -1;
            payload[index] = @intCast(value);
        }
    }
    const scalar_count = utf8ScalarCount(payload[0..payload_length]);
    if (scalar_count < 0) return -1;
    if (output == null or output_capacity < OUTPUT_BYTES) return -2;

    const result = output;
    putI64Le(result, 0, @intCast(payload_length));
    putI64Le(result, 8, scalar_count);
    return OUTPUT_BYTES;
}
