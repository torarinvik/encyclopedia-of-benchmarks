const MAX_ORDER: i64 = 31;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn hashByte(hash: u64, byte: u8) u64 {
    return (hash ^ @as(u64, byte)) *% FNV_PRIME;
}

fn hashI32(hash: u64, value: i32) u64 {
    var result = hash;
    const bits: u32 = @bitCast(value);
    for (0..4) |byte_index| result = hashByte(result, @truncate(bits >> @intCast(byte_index * 8)));
    return result;
}

export fn magic_square(n: i64) i64 {
    if (n < 1 or n > MAX_ORDER or @mod(n, 2) == 0) return -1;
    const order: usize = @intCast(n);
    var square = [_]i32{0} ** (31 * 31);
    var row = order / 2;
    var column = order - 1;
    square[row * 31 + column] = 1;
    for (2..order * order + 1) |value| {
        const next_row = (row + order - 1) % order;
        const next_column = (column + 1) % order;
        if (square[next_row * 31 + next_column] == 0) {
            row = next_row;
            column = next_column;
        } else {
            column = (column + order - 1) % order;
        }
        square[row * 31 + column] = @intCast(value);
    }
    var hash = hashByte(FNV_OFFSET, @intCast(order));
    for (0..order) |r| {
        for (0..order) |c| hash = hashI32(hash, square[r * 31 + c]);
    }
    return @intCast(hash & 0x7fffffffffffffff);
}
