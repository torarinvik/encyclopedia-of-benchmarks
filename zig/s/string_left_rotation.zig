const MAX_STRING_LENGTH = 256;
const MAX_PARSEABLE_INPUT_LENGTH = 259;

export fn string_left_rotation(input_opt: ?[*]const i64, length: usize,
                               output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const raw_length = input[0];
    const raw_rotation = input[1];
    if (raw_length < 0 or raw_length > MAX_STRING_LENGTH or raw_rotation < 0 or raw_rotation > raw_length) return -1;
    const text_length: usize = @intCast(raw_length);
    if (length != text_length + 2) return -1;
    var units: [MAX_STRING_LENGTH]u16 = [_]u16{0} ** MAX_STRING_LENGTH;
    for (0..text_length) |i| {
        if (input[i + 2] < 0 or input[i + 2] > 65535) return -1;
        units[i] = @intCast(input[i + 2]);
    }
    const required = text_length * 2;
    if (required == 0) return 0;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    const rotation: usize = @intCast(raw_rotation);
    for (0..text_length) |i| {
        var source = rotation + i;
        if (source >= text_length) source -= text_length;
        const value = units[source];
        output[2 * i] = @truncate(value);
        output[2 * i + 1] = @truncate(value >> 8);
    }
    return @intCast(required);
}
