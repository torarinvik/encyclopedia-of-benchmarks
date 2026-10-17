const DELTA: u32 = 0x9e3779b9;
const DECRYPT_SUM: u32 = 0xc6ef3720;

fn combineWords(low: u32, high: u32) u64 {
    return (@as(u64, high) << 32) | low;
}

fn teaEncrypt(block: u64, key0: u64, key1: u64) u64 {
    var b0: u32 = @truncate(block);
    var b1: u32 = @truncate(block >> 32);
    const k0: u32 = @truncate(key0);
    const k1: u32 = @truncate(key0 >> 32);
    const k2: u32 = @truncate(key1);
    const k3: u32 = @truncate(key1 >> 32);
    var sum: u32 = 0;
    for (0..32) |_| {
        sum +%= DELTA;
        b0 +%= ((b1 << 4) +% k0) ^ (b1 +% sum) ^ ((b1 >> 5) +% k1);
        b1 +%= ((b0 << 4) +% k2) ^ (b0 +% sum) ^ ((b0 >> 5) +% k3);
    }
    return (@as(u64, b1) << 32) | b0;
}

fn teaDecrypt(block: u64, key0: u64, key1: u64) u64 {
    var b0: u32 = @truncate(block);
    var b1: u32 = @truncate(block >> 32);
    const k0: u32 = @truncate(key0);
    const k1: u32 = @truncate(key0 >> 32);
    const k2: u32 = @truncate(key1);
    const k3: u32 = @truncate(key1 >> 32);
    var sum: u32 = DECRYPT_SUM;
    for (0..32) |_| {
        b1 -%= ((b0 << 4) +% k2) ^ (b0 +% sum) ^ ((b0 >> 5) +% k3);
        b0 -%= ((b1 << 4) +% k0) ^ (b1 +% sum) ^ ((b1 >> 5) +% k1);
        sum -%= DELTA;
    }
    return (@as(u64, b1) << 32) | b0;
}

fn storeU64Le(output: [*]u8, offset: usize, value: u64) void {
    for (0..8) |byte| output[offset + byte] = @truncate(value >> @as(u6, @intCast(byte * 8)));
}

fn slotBits(input: [*c]const i64, index: usize) u32 {
    const signed: i32 = @intCast(input[index]);
    return @bitCast(signed);
}

/// Return ciphertext and the decrypted round-trip block as little-endian u64s.
export fn tea(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length != 6) return -1;
    for (0..6) |index| {
        if (input[index] < -2147483648 or input[index] > 2147483647) return -1;
    }
    if (output == null or output_capacity < 16) return -2;

    const block = combineWords(slotBits(input, 0), slotBits(input, 1));
    const key0 = combineWords(slotBits(input, 2), slotBits(input, 3));
    const key1 = combineWords(slotBits(input, 4), slotBits(input, 5));
    const ciphertext = teaEncrypt(block, key0, key1);
    const recovered = teaDecrypt(ciphertext, key0, key1);
    storeU64Le(output, 0, ciphertext);
    storeU64Le(output, 8, recovered);
    return 16;
}
