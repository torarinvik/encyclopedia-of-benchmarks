fn solve(values: []const i64) i64 {
    if (values.len == 0 or values.len > 78) return -1;
    const payload_length = values[0];
    if (payload_length < 0 or payload_length > 76 or
        values.len != @as(usize, @intCast(payload_length)) + 1) return -1;
    var checksum: i64 = 0;
    for (values[1..]) |byte| {
        if (byte < 0 or byte > 127) return -1;
        checksum ^= byte;
    }
    return checksum;
}

pub export fn nmea_xor_checksum(input: [*c]const i64, length: usize) i64 {
    if (input == null or length == 0 or length > 78) return -1;
    return solve(input[0..length]);
}
