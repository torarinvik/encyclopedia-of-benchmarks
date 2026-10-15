module uint53_ones_count;

const long MAX_UINT53 = 9007199254740991;

fn long count_byte_ones(long byte) {
    long ones = 0;
    while (byte > 0) {
        long bit = byte % 2;
        ones += bit;
        byte = (byte - bit) / 2;
    }
    return ones;
}

// Count set bits in the bounded unsigned 53-bit domain, byte by byte.
fn long uint53_ones_count(long n) @export("uint53_ones_count") {
    if (n < 0 || n > MAX_UINT53) return -1;

    long ones = 0;
    while (n != 0) {
        long byte = n % 256;
        ones += count_byte_ones(byte);
        n = (n - byte) / 256;
    }
    return ones;
}
