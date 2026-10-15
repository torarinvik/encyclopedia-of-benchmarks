/// Place evens first and fill the odd section from its end.
const MAX_ARRAY_LENGTH: usize = 5000;

export fn sort_array_by_parity(input: [*]const i64, length: usize,
                               output: [*]u8, output_capacity: usize) i64 {
    if (length > MAX_ARRAY_LENGTH) return -1;
    for (0..length) |index| {
        if (input[index] < 0 or input[index] > 5000) return -1;
    }
    const output_bytes = length * 4;
    if (output_capacity < output_bytes) return -2;

    var even_index: usize = 0;
    var odd_index = length;
    for (0..length) |index| {
        const value: u32 = @intCast(input[index]);
        var destination: usize = undefined;
        if ((value & 1) == 0) {
            destination = even_index;
            even_index += 1;
        } else {
            odd_index -= 1;
            destination = odd_index;
        }
        for (0..4) |byte| output[destination * 4 + byte] = @truncate(value >> @intCast(byte * 8));
    }
    return @intCast(length);
}
