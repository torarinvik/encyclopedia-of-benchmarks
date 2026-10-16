const MAX_INPUT_LENGTH: usize = 10;
const PACKED_INPUT_LENGTH: usize = MAX_INPUT_LENGTH + 1;
const OUTPUT_LENGTH: usize = 8;

fn isDigit(value: i64) bool {
    return value >= 48 and value <= 57;
}

export fn railway_time_conversion(values: [*c]const i64, length: usize,
                                  output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != PACKED_INPUT_LENGTH) return -1;
    if (values[0] != @as(i64, @intCast(MAX_INPUT_LENGTH))) return -1;

    if (values[3] != 58 or values[6] != 58 or
        !((values[9] == 65 and values[10] == 77) or
          (values[9] == 80 and values[10] == 77)) or
        !isDigit(values[1]) or !isDigit(values[2]) or
        !isDigit(values[4]) or !isDigit(values[5]) or
        !isDigit(values[7]) or !isDigit(values[8])) return -1;

    const hour: i64 = (values[1] - 48) * 10 + values[2] - 48;
    const minute: i64 = (values[4] - 48) * 10 + values[5] - 48;
    const second: i64 = (values[7] - 48) * 10 + values[8] - 48;
    if (hour < 1 or hour > 12 or minute > 59 or second > 59) return -1;
    if (output == null or output_capacity < OUTPUT_LENGTH) return -2;

    const hour24: i64 = @rem(hour, 12) + (if (values[9] == 80) 12 else 0);
    output[0] = @intCast(48 + @divTrunc(hour24, 10));
    output[1] = @intCast(48 + @rem(hour24, 10));
    output[2] = 58;
    output[3] = @intCast(values[4]);
    output[4] = @intCast(values[5]);
    output[5] = 58;
    output[6] = @intCast(values[7]);
    output[7] = @intCast(values[8]);
    return OUTPUT_LENGTH;
}
