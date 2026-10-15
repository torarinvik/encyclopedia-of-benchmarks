/// Emit the pinned minimal-width two's-complement string for a signed integer.
export fn twos_complement(value: i64, output: [*]u8, output_capacity: usize) i64 {
    if (value > 0) return -1;
    if (value == 0) {
        if (output_capacity < 3) return -2;
        output[0] = '0'; output[1] = 'b'; output[2] = '0';
        return 3;
    }
    const magnitude: u64 = @as(u64, @intCast(-(value + 1))) + 1;
    var bit_length: usize = 0;
    var remaining = magnitude;
    while (remaining > 0) : (bit_length += 1) remaining >>= 1;
    const suffix = if (bit_length == 64) magnitude else (@as(u64, 1) << @intCast(bit_length)) - magnitude;
    var bits: [64]u8 = undefined;
    var bit_count: usize = 0;
    remaining = suffix;
    while (remaining > 0) : (bit_count += 1) {
        bits[bit_count] = '0' + @as(u8, @intCast(remaining & 1));
        remaining >>= 1;
    }
    const required = bit_length + 3;
    if (output_capacity < required) return -2;
    var position: usize = 0;
    output[position] = '0'; position += 1;
    output[position] = 'b'; position += 1;
    output[position] = '1'; position += 1;
    var zero_count = bit_length - bit_count;
    while (zero_count > 0) : (zero_count -= 1) {
        output[position] = '0';
        position += 1;
    }
    while (bit_count > 0) {
        bit_count -= 1;
        output[position] = bits[bit_count];
        position += 1;
    }
    return @intCast(position);
}
