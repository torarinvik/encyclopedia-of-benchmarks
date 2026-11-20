const MAX_ORDER: i64 = 30;
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

export fn magic_square_singly_even_strachey(n: i64) i64 {
    if (n < 6 or n > MAX_ORDER or @mod(n, 4) != 2) return -1;
    const order: usize = @intCast(n);
    const half = order / 2;
    const k = half / 2;
    const block_size = half * half;
    var odd = [_]i32{0} ** (30 * 30);
    var square = [_]i32{0} ** (30 * 30);

    var row: usize = 0;
    var column = half / 2;
    odd[row * 30 + column] = 1;
    for (2..block_size + 1) |value| {
        const next_row = (row + half - 1) % half;
        const next_column = (column + 1) % half;
        if (odd[next_row * 30 + next_column] == 0) {
            row = next_row;
            column = next_column;
        } else {
            row = (row + 1) % half;
        }
        odd[row * 30 + column] = @intCast(value);
    }

    for (0..half) |r| {
        for (0..half) |c| {
            const value = odd[r * 30 + c];
            square[r * 30 + c] = value;
            square[r * 30 + half + c] = value + @as(i32, @intCast(2 * block_size));
            square[(half + r) * 30 + c] = value + @as(i32, @intCast(3 * block_size));
            square[(half + r) * 30 + half + c] = value + @as(i32, @intCast(block_size));
        }
    }

    for (0..half) |r| {
        for (0..k) |c| {
            const top = r * 30 + c;
            const bottom = (half + r) * 30 + c;
            const saved = square[top]; square[top] = square[bottom]; square[bottom] = saved;
        }
        for (half - (k - 1)..half) |c| {
            const top = r * 30 + half + c;
            const bottom = (half + r) * 30 + half + c;
            const saved = square[top]; square[top] = square[bottom]; square[bottom] = saved;
        }
    }
    {
        const top = k * 30;
        const bottom = (half + k) * 30;
        const saved = square[top]; square[top] = square[bottom]; square[bottom] = saved;
    }
    {
        const top = k * 30 + k;
        const bottom = (half + k) * 30 + k;
        const saved = square[top]; square[top] = square[bottom]; square[bottom] = saved;
    }

    var hash = hashByte(FNV_OFFSET, @intCast(order));
    for (0..order) |r| { for (0..order) |c| { hash = hashI32(hash, square[r * 30 + c]); } }
    return @intCast(hash & 0x7fffffffffffffff);
}
