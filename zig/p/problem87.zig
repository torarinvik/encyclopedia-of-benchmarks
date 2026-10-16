const std = @import("std");
fn integerSqrt(value: i64) i64 { var root: i64 = 0; while ((root + 1) * (root + 1) <= value) : (root += 1) {} return root; }
export fn problem87(limit: i64) i64 {
    if (limit < 24 or limit > 50_000_000) return -1;
    const root = integerSqrt(limit - 24);
    const bound: usize = @intCast(@max(root, 2));
    const allocator = std.heap.page_allocator;
    const prime = allocator.alloc(bool, bound + 1) catch return -1; defer allocator.free(prime); @memset(prime, true); prime[0] = false; prime[1] = false;
    for (2..bound + 1) |p| if (p * p <= bound and prime[p]) { var multiple = p * p; while (multiple <= bound) : (multiple += p) prime[multiple] = false; };
    const bytes: usize = @intCast(@divTrunc(limit + 7, 8));
    const seen = allocator.alloc(u8, bytes) catch return -1; defer allocator.free(seen); @memset(seen, 0);
    for (2..bound + 1) |p1| if (prime[p1]) {
        const square: i64 = @intCast(p1 * p1);
        for (2..bound + 1) |p2| if (prime[p2]) {
            const cube: i64 = @intCast(p2 * p2 * p2);
            if (square + cube >= limit - 16) break;
            for (2..bound + 1) |p3| if (prime[p3]) {
                const total = square + cube + @as(i64, @intCast(p3 * p3 * p3 * p3));
                if (total >= limit) break;
                const index: usize = @intCast(total);
                seen[index >> 3] |= @as(u8, 1) << @intCast(total & 7);
            };
        };
    };
    var count: i64 = 0; for (seen) |byte| count += @as(i64, @intCast(@popCount(byte))); return count;
}
