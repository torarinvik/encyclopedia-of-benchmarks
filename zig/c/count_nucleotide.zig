fn decimalLength(value: i64) usize {
    var current = value;
    var length: usize = 1;
    while (current >= 10) : (length += 1) { current /= 10; }
    return length;
}

fn writeDecimal(output: [*c]u8, offset: usize, value: i64) usize {
    var current = value;
    var divisor: i64 = 1;
    while (current / divisor >= 10) { divisor *= 10; }
    var position = offset;
    while (divisor > 0) {
        output[position] = @intCast(48 + current / divisor);
        position += 1;
        current %= divisor;
        divisor /= 10;
    }
    return position;
}

export fn count_nucleotide(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 1 or length > 1_001) return -1;
    const count_value = values[0];
    if (count_value < 0 or count_value > 1_000 or length != @as(usize, @intCast(count_value)) + 1) return -1;
    var count_a: i64 = 0;
    var count_c: i64 = 0;
    var count_g: i64 = 0;
    var count_t: i64 = 0;
    for (0..@as(usize, @intCast(count_value))) |i| {
        const codepoint = values[1 + i];
        if (codepoint < 0 or codepoint > 127) return -1;
        if (codepoint == 65) count_a += 1
        else if (codepoint == 67) count_c += 1
        else if (codepoint == 71) count_g += 1
        else if (codepoint == 84) count_t += 1;
    }
    const output_length = decimalLength(count_a) + decimalLength(count_c) +
        decimalLength(count_g) + decimalLength(count_t) + 3;
    if (output == null or capacity < output_length) return -2;
    var offset = writeDecimal(output, 0, count_a); output[offset] = 32; offset += 1;
    offset = writeDecimal(output, offset, count_c); output[offset] = 32; offset += 1;
    offset = writeDecimal(output, offset, count_g); output[offset] = 32; offset += 1;
    offset = writeDecimal(output, offset, count_t);
    return @intCast(offset);
}
