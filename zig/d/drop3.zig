const MAX_INPUT: usize = 4096;
const OFFSETS = [_]usize{ 0, 5, 2, 7, 4, 1, 6, 3 };

export fn drop3(values: [*c]const i64, length: usize) i64 {
    if (length > MAX_INPUT + 1 or (length != 0 and values == null)) return -1;
    for (0..length) |index| {
        const value = values[index];
        if (value < 0 or value > 255) return -1;
    }
    if (length > MAX_INPUT) return -1;

    var output_size: i64 = 0;
    for (0..20) |_| {
        var input_index: usize = 0;
        var remaining_bits = length * 8;
        var phase: usize = 0;
        var bit_buffer: u16 = 0;
        var output_bits: usize = 0;
        while (remaining_bits >= 3) {
            remaining_bits -= 3;
            const offset = OFFSETS[phase];
            if (offset < 3) {
                bit_buffer |= @as(u16, @intCast(values[input_index])) << @as(u4, @intCast(8 - offset));
                input_index += 1;
            }
            const code = (bit_buffer >> 13) & 7;
            if (code >= 4) output_bits += 3;
            bit_buffer = bit_buffer << 3;
            phase = (phase + 1) & 7;
        }
        output_size = @intCast(output_bits >> 3);
    }
    return output_size;
}
