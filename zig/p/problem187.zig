const std = @import("std");

fn isComposite(bits: []u64, value: i64) bool {
    const word: usize = @intCast(value >> 6);
    const shift: u6 = @intCast(value & 63);
    return (bits[word] & (@as(u64, 1) << shift)) != 0;
}
fn markComposite(bits: []u64, value: i64) void {
    const word: usize = @intCast(value >> 6);
    const shift: u6 = @intCast(value & 63);
    bits[word] |= @as(u64, 1) << shift;
}

export fn problem187(max_number: i64) i64 {
    if (max_number < 0 or max_number > 100_000_000) return -1;
    const prime_limit = @divTrunc(max_number, 2);
    if (prime_limit <= 2) return 0;
    const allocator = std.heap.page_allocator;
    const words: usize = @intCast(@divTrunc(prime_limit + 63, 64));
    const composite = allocator.alloc(u64, words) catch return -1;
    defer allocator.free(composite);
    @memset(composite, 0);
    markComposite(composite, 0);
    markComposite(composite, 1);

    var prime: i64 = 2;
    while (prime <= @divTrunc(prime_limit - 1, prime)) : (prime += 1) {
        if (isComposite(composite, prime)) continue;
        var multiple = prime * prime;
        while (multiple < prime_limit) : (multiple += prime) markComposite(composite, multiple);
    }

    var right_value = prime_limit - 1;
    while (right_value >= 2 and isComposite(composite, right_value)) : (right_value -= 1) {}
    if (right_value < 2) return 0;
    var prime_count: i64 = 0;
    var value: i64 = 2;
    while (value <= right_value) : (value += 1) {
        if (!isComposite(composite, value)) prime_count += 1;
    }

    var right_rank = prime_count - 1;
    var left_rank: i64 = 0;
    var count: i64 = 0;
    var left_value: i64 = 2;
    while (left_value <= right_value) : (left_value += 1) {
        if (isComposite(composite, left_value)) continue;
        while (right_rank >= left_rank and left_value * right_value >= max_number) {
            right_rank -= 1;
            right_value -= 1;
            while (right_value >= 2 and isComposite(composite, right_value)) right_value -= 1;
        }
        if (right_rank < left_rank) break;
        count += right_rank - left_rank + 1;
        left_rank += 1;
    }
    return count;
}
