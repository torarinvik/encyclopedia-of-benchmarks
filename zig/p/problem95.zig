const std = @import("std");
const MARK: u32 = 0x80000000;
const MASK: u32 = 0x7fffffff;
export fn problem95(limit: i64) i64 {
    if (limit < 1 or limit > 1_000_000) return -1;
    const allocator = std.heap.page_allocator;
    const n: usize = @intCast(limit);
    const sums = allocator.alloc(u32, n + 1) catch return -1;
    defer allocator.free(sums);
    @memset(sums, 0);
    for (1..n / 2 + 1) |divisor| { var multiple = 2 * divisor; while (multiple <= n) : (multiple += divisor) sums[multiple] += @intCast(divisor); }
    var best_length: usize = 0;
    var answer: i64 = 0;
    for (2..n + 1) |start| {
        var current = sums[start]; var length: usize = 1; sums[start] |= MARK;
        while (current > 1 and current <= n and sums[current] & MARK == 0) { sums[current] |= MARK; current = sums[current] & MASK; length += 1; }
        if (current == start and length > best_length) { best_length = length; answer = @intCast(start); }
        current = @intCast(start);
        for (0..length) |_| { const next = sums[current] & MASK; sums[current] = next; current = next; }
    }
    return answer;
}
