extern "c" fn calloc(count: usize, size: usize) ?[*]u8;
extern "c" fn free(ptr: ?[*]u8) void;

export fn problem10(limit: i64) i64 {
    if (limit < 0 or limit > 2_000_000) return -1;
    const composite = calloc(1_000_000, 1) orelse return -1;
    defer free(composite);
    const odd_count: usize = @intCast(@divTrunc(limit, 2));
    var total: i64 = if (limit > 2) 2 else 0;
    var prime: i64 = 3;
    while (prime * prime < limit) : (prime += 2) {
        if (composite[@intCast(@divTrunc(prime, 2))] == 0) {
            var index: i64 = @divTrunc(prime * prime, 2);
            while (index < odd_count) : (index += prime) {
                composite[@intCast(index)] = 1;
            }
        }
    }
    var index: usize = 1;
    while (index < odd_count) : (index += 1) {
        if (composite[index] == 0) total += @intCast(2 * index + 1);
    }
    return total;
}
