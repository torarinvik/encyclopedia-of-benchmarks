const MAX_REQUESTS: i64 = 63;
const MAX_INPUT: usize = 66;

export fn token_bucket_rate_limiter_virtual_time(packed: ?[*]const i64, length: usize) i64 {
    if (length < 3 or length > MAX_INPUT) return -1;
    const input = packed orelse return -1;
    const capacity = input[0];
    const rate = input[1];
    const qv = input[2];
    if (capacity < 0 or capacity > 64 or rate < 0 or rate > 32 or qv < 0 or qv > MAX_REQUESTS or
        length != 3 + @as(usize, @intCast(qv))) return -1;
    const q: usize = @intCast(qv);
    for (0..q) |i| if (input[3 + i] < 0 or input[3 + i] > 256) return -1;

    var tokens = capacity;
    var allowed: u64 = 0;
    for (0..q) |i| {
        tokens += input[3 + i] * rate;
        if (tokens > capacity) tokens = capacity;
        if (tokens > 0) {
            allowed |= @as(u64, 1) << @as(u6, @intCast(i));
            tokens -= 1;
        }
    }
    return @intCast(allowed);
}
