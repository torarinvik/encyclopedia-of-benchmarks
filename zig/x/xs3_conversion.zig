export fn xs3_conversion(packed: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const direction = packed[0];
    var value = packed[1];
    if (direction == 0) {
        if (value < 0 or value > 2_147_483_647) return -1;
        var decoded: i64 = 0;
        var multiplier: i64 = 1;
        while (value > 0) {
            const nibble = value & 0xF;
            if (nibble < 3 or nibble > 12) return -1;
            decoded += (nibble - 3) * multiplier;
            multiplier *= 10;
            value >>= 4;
        }
        return decoded;
    }
    if (direction == 1) {
        if (value < 0 or value > 9_999_999) return -1;
        var encoded: i64 = 0;
        var shift: u6 = 0;
        while (value > 0) {
            const digit = value % 10 + 3;
            encoded |= digit << (shift * 4);
            value = @divTrunc(value, 10);
            shift += 1;
        }
        return encoded;
    }
    return -1;
}
