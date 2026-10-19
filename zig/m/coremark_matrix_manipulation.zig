fn crcByte(value0: u8, crc0: u16) u16 {
    var value = value0;
    var crc = crc0;
    for (0..8) |_| {
        const mix: u8 = (value & 1) ^ @as(u8, @truncate(crc & 1));
        value >>= 1;
        if (mix != 0) crc ^= 0x4002;
        crc >>= 1;
        if (mix != 0) crc |= 0x8000 else crc &= 0x7fff;
    }
    return crc;
}

fn crc16(value: i16, crc: u16) u16 {
    const bits: u16 = @bitCast(value);
    return crcByte(@truncate(bits >> 8), crcByte(@truncate(bits), crc));
}

fn matrixSum(c: [9]i32, clip: i16) i16 {
    var tmp: i32 = 0;
    var prev: i32 = 0;
    var ret: i16 = 0;
    for (c) |cur| {
        tmp += cur;
        if (tmp > @as(i32, clip)) {
            ret += 10;
            tmp = 0;
        } else if (cur > prev) {
            ret += 1;
        }
        prev = cur;
    }
    return ret;
}

fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[offset + b] = @truncate(bits >> @intCast(b * 8));
}

export fn coremark_matrix_manipulation(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 19) return -1;
    const raw = input[0];
    if (raw < 0 or raw > 15) return -1;
    var a: [9]i16 = @splat(0);
    var b: [9]i16 = @splat(0);
    for (0..9) |i| {
        if (input[1 + i] < 0 or input[1 + i] > 127 or input[10 + i] < 0 or input[10 + i] > 127) return -1;
        a[i] = @intCast(input[1 + i]);
        b[i] = @intCast(input[10 + i]);
    }
    if (output == null or capacity < 112) return -2;
    const value: i16 = @intCast(raw);
    const clip: i16 = value - 4096;
    var c: [9]i32 = @splat(0);
    var sums: [4]i16 = @splat(0);
    for (0..9) |i| {
        a[i] += value;
        c[i] = @as(i32, a[i]) * @as(i32, value);
    }
    sums[0] = matrixSum(c, clip);
    for (0..3) |i| {
        c[i] = 0;
        for (0..3) |j| c[i] += @as(i32, a[i * 3 + j]) * @as(i32, b[j]);
    }
    sums[1] = matrixSum(c, clip);
    for (0..3) |i| {
        for (0..3) |j| {
            c[i * 3 + j] = 0;
            for (0..3) |k| c[i * 3 + j] += @as(i32, a[i * 3 + k]) * @as(i32, b[k * 3 + j]);
        }
    }
    sums[2] = matrixSum(c, clip);
    for (0..3) |i| {
        for (0..3) |j| {
            c[i * 3 + j] = 0;
            for (0..3) |k| {
                const product = @as(i32, a[i * 3 + k]) * @as(i32, b[k * 3 + j]);
                c[i * 3 + j] += ((product >> 2) & 0xf) * ((product >> 5) & 0x7f);
            }
        }
    }
    sums[3] = matrixSum(c, clip);
    var crc: u16 = 0;
    for (sums) |sum| crc = crc16(sum, crc);
    for (0..9) |i| a[i] -= value;
    var result: [14]i64 = @splat(0);
    result[0] = crc;
    for (0..4) |i| result[i + 1] = sums[i];
    for (0..9) |i| result[i + 5] = a[i];
    for (0..14) |i| putI64(output, i * 8, result[i]);
    return 112;
}
