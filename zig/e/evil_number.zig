/// Return 1 when a nonnegative integer has an even popcount.
export fn evil_number(input: i64) i64 {
    if (input < 0) return -1;
    var remaining: u64 = @intCast(input);
    var count: u64 = 0;
    while (remaining > 0) {
        count += remaining & 1;
        remaining >>= 1;
    }
    return if (count % 2 == 0) 1 else 0;
}
