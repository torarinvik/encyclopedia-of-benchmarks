const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn hashByte(hash: u64, byte: u8) u64 {
    return (hash ^ @as(u64, byte)) *% FNV_PRIME;
}

fn hashI32(hash: u64, value: i32) u64 {
    var result = hash;
    const bits: u32 = @bitCast(value);
    for (0..4) |byte_index| {
        result = hashByte(result, @truncate(bits >> @intCast(byte_index * 8)));
    }
    return result;
}

export fn magic_square_doubly_even_complement(n: i64) i64 {
    if (n < 4 or n > 64 or @mod(n, 4) != 0) return -1;
    const order: i32 = @intCast(n);
    const order_usize: usize = @intCast(order);
    const ceiling = order * order + 1;
    var hash = hashByte(FNV_OFFSET, @intCast(order));

    for (0..order_usize) |row| {
        for (0..order_usize) |column| {
            var value: i32 = @intCast(row * order_usize + column + 1);
            const local_row = row % 4;
            const local_column = column % 4;
            if (local_row == local_column or local_row + local_column == 3) {
                value = ceiling - value;
            }
            hash = hashI32(hash, value);
        }
    }
    return @intCast(hash & 0x7fffffffffffffff);
}
