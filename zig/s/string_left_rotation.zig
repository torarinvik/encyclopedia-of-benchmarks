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
    if (text_length == 0) return 0;
    var units: [MAX_STRING_LENGTH]u16 = @splat(0);
    var observed_bits: u64 = 0;
    for (0..text_length) |i| {
        const value: u64 = @bitCast(input[i + 2]);
        observed_bits |= value;
        units[i] = @truncate(value);
    }
    if (observed_bits > 65535) return -1;
    const required = text_length * 2;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    const rotation: usize = @intCast(raw_rotation);
    for (rotation..text_length) |source| {
        const destination = 2 * (source - rotation);
        const value = units[source];
        output[destination] = @truncate(value);
        output[destination + 1] = @truncate(value >> 8);
    }
    const suffix_bytes = 2 * (text_length - rotation);
    for (0..rotation) |source| {
        const destination = suffix_bytes + 2 * source;
        const value = units[source];
        output[destination] = @truncate(value);
        output[destination + 1] = @truncate(value >> 8);
    }
    return @intCast(required);
}
