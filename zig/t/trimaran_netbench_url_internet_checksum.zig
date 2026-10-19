// Modified source-related port of NetBench url.c; see bundled LICENSE_NOTICE.txt.
export fn trimaran_netbench_url_internet_checksum(values: [*c]const i64, length: usize) i64 {
    const max_bytes: usize = 64;
    if (values == null or length < 2 or length > max_bytes + 2) return -1;
    const mode = values[0];
    const count_value = values[1];
    if ((mode != 0 and mode != 1) or count_value < 0 or count_value > 64 or
        length != @as(usize, @intCast(count_value)) + 2) return -1;
    const count: usize = @intCast(count_value);
    for (0..count) |i| if (values[i + 2] < 0 or values[i + 2] > 255) return -1;
    var sum: u64 = 0;
    var i: usize = 0;
    while (i + 1 < count) : (i += 2) {
        const word: u64 = @intCast(values[i + 2]) | (@as(u64, @intCast(values[i + 3])) << 8);
        sum = sum -% (word +% 1);
    }
    if (i < count) sum = sum +% @as(u64, @intCast(values[i + 2]));
    while (sum >> 16 != 0) sum = (sum & 0xffff) + (sum >> 16);
    if (mode == 1) sum = ((sum >> 8) | ((sum << 8) & 0xff00)) & 0xffff;
    return @intCast(sum);
}
