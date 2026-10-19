const MAX_CHARACTERS: usize = 31;
const MAX_OUTPUT_BYTES: usize = 1 + 2 * MAX_CHARACTERS;

export fn misc_lowercase(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 1 or input_length > MAX_CHARACTERS + 2) return -1;
    const raw_length = input[0];
    if (raw_length < 0 or raw_length > MAX_CHARACTERS or input_length != @as(usize, @intCast(raw_length)) + 1) return -1;
    const length: usize = @intCast(raw_length);
    var lowered: [MAX_CHARACTERS]u16 = undefined;
    var ascii_flag: u8 = 1;
    for (0..length) |index| {
        const raw = input[index + 1];
        if (raw < 0 or raw > 65535) return -1;
        const value: u16 = @intCast(raw);
        if (value > 0x7f) ascii_flag = 0;
        lowered[index] = value + @as(u16, if (value >= 'A' and value <= 'Z') 32 else 0);
    }
    const required = 1 + 2 * length;
    if (output == null or output_capacity < required) return -2;
    var staged: [MAX_OUTPUT_BYTES]u8 = undefined;
    staged[0] = ascii_flag;
    for (0..length) |index| {
        staged[1 + 2 * index] = @truncate(lowered[index]);
        staged[2 + 2 * index] = @truncate(lowered[index] >> 8);
    }
    for (0..required) |index| output[index] = staged[index];
    return @intCast(required);
}
