fn nimProduct(a: u64, b: u64, width: u32) u64 {
    if (width == 1) return a & b;
    const half = width / 2;
    const shift: u6 = @intCast(half);
    const mask = (@as(u64, 1) << shift) - 1;
    const a_low = a & mask;
    const a_high = a >> shift;
    const b_low = b & mask;
    const b_high = b >> shift;
    const low_product = nimProduct(a_low, b_low, half);
    const high_product = nimProduct(a_high, b_high, half);
    const cross = nimProduct(a_low ^ a_high, b_low ^ b_high, half)
                ^ low_product ^ high_product;
    const constant = @as(u64, 1) << @intCast(half - 1);
    const low = low_product ^ nimProduct(high_product, constant, half);
    const high = cross ^ high_product;
    return low ^ (high << shift);
}

export fn nim_product_64(input: ?[*]const i64, length: usize,
                         output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length != 4) return -1;
    const values = input.?[0..4];
    for (values) |value| {
        if (value < 0 or value > 4_294_967_295) return -1;
    }
    const out = output orelse return -2;
    if (output_capacity < 8) return -2;

    const a = @as(u64, @intCast(values[0])) | (@as(u64, @intCast(values[1])) << 32);
    const b = @as(u64, @intCast(values[2])) | (@as(u64, @intCast(values[3])) << 32);
    const result = nimProduct(a, b, 64);
    for (0..8) |index| out[index] = @truncate(result >> @intCast(8 * index));
    return 8;
}
