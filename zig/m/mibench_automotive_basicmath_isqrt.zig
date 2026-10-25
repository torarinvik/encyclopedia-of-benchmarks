export fn mibench_automotive_basicmath_isqrt(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length != 1 or input[0] < 0 or input[0] > 65535) return -1;
    var x: u32 = @intCast(input[0]);
    var root: u32 = 0;
    var remainder: u32 = 0;
    for (0..32) |_| {
        remainder = (remainder << 2) + (x >> 30);
        x <<= 2;
        root <<= 1;
        const trial = (root << 1) + 1;
        if (remainder >= trial) {
            remainder -= trial;
            root += 1;
        }
    }
    return @intCast(root);
}
