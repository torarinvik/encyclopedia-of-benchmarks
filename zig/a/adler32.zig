const MAX_LENGTH: usize = 100_001;
const ADLER_MOD: i64 = 65_521;

/// Compute the standard Adler-32 checksum of byte values in the input array.
export fn adler32(values: [*c]const i64, length: usize) i64 {
    if (length > MAX_LENGTH or (length != 0 and values == null)) return -1;
    var a: i64 = 1;
    var b: i64 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < 0 or value > 255) return -1;
        a = @rem(a + value, ADLER_MOD);
        b = @rem(b + a, ADLER_MOD);
    }
    return (b << 16) | a;
}
