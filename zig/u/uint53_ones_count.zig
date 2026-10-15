/// Count set bits in the bounded unsigned 53-bit domain, byte by byte.
const MAX_UINT53: i64 = 9_007_199_254_740_991;

fn countByteOnes(byte: i64) i64 {
    var current = byte;
    var ones: i64 = 0;
    while (current > 0) {
        const bit = @mod(current, 2);
        ones += bit;
        current = @divTrunc(current - bit, 2);
    }
    return ones;
}

export fn uint53_ones_count(n: i64) i64 {
    if (n < 0 or n > MAX_UINT53) return -1;

    var current = n;
    var ones: i64 = 0;
    while (current != 0) {
        const byte = @mod(current, 256);
        ones += countByteOnes(byte);
        current = @divTrunc(current - byte, 256);
    }
    return ones;
}
