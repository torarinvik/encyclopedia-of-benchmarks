fn unsignedBits(value_in: u32, bits: *[80]u8) usize {
    var value = value_in;
    var length: usize = 0;
    while (true) {
        bits[length] = '0' + @as(u8, @intCast(value & 1));
        length += 1;
        value >>= 1;
        if (value == 0) break;
    }
    var left: usize = 0;
    while (left < length / 2) : (left += 1) {
        const right = length - left - 1;
        const temporary = bits[left]; bits[left] = bits[right]; bits[right] = temporary;
    }
    return length;
}

export fn binary_shifts(values: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length != 3) return -1;
    const operation = values[0];
    const number = values[1];
    const shift = values[2];
    if (operation < 0 or operation > 2 or number < -2147483647 or number > 2147483647 or
        shift < 0 or shift > 31 or (operation < 2 and number < 0)) return -1;
    var bits: [80]u8 = undefined;
    var result: [82]u8 = undefined;
    var bits_length: usize = 0;
    var result_length: usize = 0;
    if (operation == 0 or operation == 1) {
        bits_length = unsignedBits(@intCast(number), &bits);
        result[0] = '0'; result[1] = 'b'; result_length = 2;
        if (operation == 0) {
            @memcpy(result[result_length .. result_length + bits_length], bits[0..bits_length]);
            result_length += bits_length;
            for (0..@intCast(shift)) |_| { result[result_length] = '0'; result_length += 1; }
        } else if (@as(usize, @intCast(shift)) >= bits_length) {
            result[result_length] = '0'; result_length += 1;
        } else {
            const kept = bits_length - @as(usize, @intCast(shift));
            @memcpy(result[result_length .. result_length + kept], bits[0..kept]);
            result_length += kept;
        }
    } else {
        if (number >= 0) {
            bits[0] = '0';
            var ordinary: [80]u8 = undefined;
            const ordinary_length = unsignedBits(@intCast(number), &ordinary);
            @memcpy(bits[1 .. 1 + ordinary_length], ordinary[0..ordinary_length]);
            bits_length = 1 + ordinary_length;
        } else {
            const magnitude: u32 = @intCast(-number);
            const magnitude_length = unsignedBits(magnitude, &bits);
            const complement = (@as(u32, 1) << @intCast(magnitude_length)) - magnitude;
            var complement_bits: [80]u8 = undefined;
            const complement_length = unsignedBits(complement, &complement_bits);
            bits[0] = '1';
            var position: usize = 1;
            for (complement_length..magnitude_length) |_| { bits[position] = '0'; position += 1; }
            @memcpy(bits[position .. position + complement_length], complement_bits[0..complement_length]);
            bits_length = position + complement_length;
        }
        result[0] = '0'; result[1] = 'b'; result_length = 2;
        const sign = bits[0];
        if (@as(usize, @intCast(shift)) >= bits_length) {
            for (0..bits_length) |_| { result[result_length] = sign; result_length += 1; }
        } else {
            for (0..@intCast(shift)) |_| { result[result_length] = sign; result_length += 1; }
            const kept = bits_length - @as(usize, @intCast(shift));
            @memcpy(result[result_length .. result_length + kept], bits[0..kept]);
            result_length += kept;
        }
    }
    if (output_capacity < result_length) return -2;
    @memcpy(output[0..result_length], result[0..result_length]);
    return @intCast(result_length);
}
