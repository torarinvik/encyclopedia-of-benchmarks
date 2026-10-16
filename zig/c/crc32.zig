const MAX_LENGTH: usize = 100_001;
const POLYNOMIAL: i64 = 3_988_292_384;
const INITIAL: i64 = 4_294_967_295;
export fn crc32(values: [*c]const i64, length: usize) i64 {
    if (length > MAX_LENGTH or (length != 0 and values == null)) return -1;
    var crc: i64 = INITIAL;
    for (0..length) |index| {
        const value = values[index];
        if (value < 0 or value > 255) return -1;
        crc ^= value;
        for (0..8) |_| {
            if ((crc & 1) != 0) crc = (crc >> 1) ^ POLYNOMIAL else crc >>= 1;
        }
    }
    return crc ^ INITIAL;
}
