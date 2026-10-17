/// Bounded AddPadding, RemovePadding, and GetPaddingCount source extraction.
export fn pkcs7_padding(input: [*c]const i64, length: usize,
                        output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 5 or length > 69) return -1;
    const operation = input[0];
    const block_arg = input[1];
    const offset_arg = input[2];
    const data_arg = input[3];
    if (operation < 0 or operation > 2 or block_arg < 1 or block_arg > 16 or
        data_arg < 1 or data_arg > 64 or
        (operation == 0 and (offset_arg < 0 or offset_arg > data_arg)) or
        length != @as(usize, @intCast(data_arg)) + 4) return -1;
    const block_size: usize = @intCast(block_arg);
    const offset: usize = if (operation == 0) @intCast(offset_arg) else 0;
    const data_length: usize = @intCast(data_arg);
    for (0..data_length) |index| {
        const value = input[index + 4];
        if (value < 0 or value > 255) return -1;
    }

    var padding_count: usize = 0;
    var output_length: usize = 0;
    if (operation == 0) {
        padding_count = block_size - data_length % block_size;
        if (offset + padding_count > data_length) return -1;
        output_length = data_length + 1;
    } else if (operation == 1) {
        if (data_length % block_size != 0) return -1;
        padding_count = @intCast(input[data_length + 3]);
        if (padding_count == 0 or padding_count > block_size) return -1;
        for (data_length - padding_count..data_length) |index| {
            if (@as(usize, @intCast(input[index + 4])) != padding_count) return -1;
        }
        output_length = data_length - padding_count;
    } else {
        padding_count = @intCast(input[data_length + 3]);
        const padding_start: i64 = @intCast(data_length);
        const signed_start = padding_start - @as(i64, @intCast(padding_count));
        const invalid_bits = signed_start | (@as(i64, @intCast(padding_count)) - 1);
        var padding_check_failed = -@as(i64, @intCast(@as(u64, @bitCast(invalid_bits)) >> 63));
        for (0..data_length) |index| {
            const difference = @as(i64, @intCast(index)) - signed_start;
            const negative_bit = @as(u64, @bitCast(difference)) >> 63;
            const mask = -@as(i64, @intCast(1 - negative_bit));
            padding_check_failed |= (input[index + 4] ^ @as(i64, @intCast(padding_count))) & mask;
        }
        if (padding_check_failed != 0) return -1;
        output_length = 1;
    }
    if (output == null or output_capacity < output_length) return -2;
    if (operation == 0) {
        output[0] = @intCast(padding_count);
        for (0..data_length) |index| {
            const value: i64 = if (index >= offset and index < offset + padding_count)
                @intCast(padding_count)
            else
                input[index + 4];
            output[index + 1] = @intCast(value);
        }
    } else if (operation == 1) {
        for (0..output_length) |index| output[index] = @intCast(input[index + 4]);
    } else {
        output[0] = @intCast(padding_count);
    }
    return @intCast(output_length);
}
