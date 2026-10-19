const MAX_LENGTH: usize = 256;
const POLYNOMIAL: u64 = 0x04c11db7;
const OUTPUT_MASK: u64 = 0xffff_ffff;

export fn netbench_crc(values_opt: ?[*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH or (length != 0 and values_opt == null)) return -1;
    const values = values_opt orelse return 0;
    for (0..length) |index| {
        if (values[index] < 0 or values[index] > 255) return -1;
    }

    var table: [256]u64 = undefined;
    for (0..256) |byte| {
        var remainder: u64 = @as(u64, @intCast(byte)) << 24;
        for (0..8) |_| {
            if ((remainder & 0x8000_0000) != 0) {
                remainder = (remainder << 1) ^ POLYNOMIAL;
            } else {
                remainder <<= 1;
            }
        }
        table[byte] = remainder;
    }

    var crc: u64 = 0;
    for (0..length) |index| {
        const byte: u64 = @intCast(values[index]);
        const table_index: usize = @intCast(((crc >> 24) ^ byte) & 0xff);
        crc = (crc << 8) ^ table[table_index];
    }
    return @intCast(crc & OUTPUT_MASK);
}
