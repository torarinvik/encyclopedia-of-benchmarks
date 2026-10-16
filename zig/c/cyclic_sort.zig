pub export fn cyclic_sort(values: [*c]const i64, length: usize,
                          output: [*c]u8, output_capacity: usize) i64 {
    const max_length: usize = 1024;
    if (length > max_length or (length > 0 and values == null)) return -1;
    var seen: [max_length + 1]bool = @splat(false);
    for (0..length) |index| {
        const value = values[index];
        if (value < 1 or value > @as(i64, @intCast(length)) or seen[@intCast(value)]) return -1;
        seen[@intCast(value)] = true;
    }

    var sorted: [max_length]i64 = @splat(0);
    for (0..length) |index| sorted[index] = values[index];
    var index: usize = 0;
    while (index < length) {
        const destination: usize = @intCast(sorted[index] - 1);
        if (destination == index) {
            index += 1;
        } else {
            const temporary = sorted[index];
            sorted[index] = sorted[destination];
            sorted[destination] = temporary;
        }
    }

    const output_length = length * 8;
    if (output_length > output_capacity or (output_length > 0 and output == null)) return -2;
    for (0..length) |item| {
        const bits: u64 = @intCast(sorted[item]);
        for (0..8) |byte|
            output[item * 8 + byte] = @intCast((bits >> @intCast(byte * 8)) & 255);
    }
    return @intCast(length);
}
