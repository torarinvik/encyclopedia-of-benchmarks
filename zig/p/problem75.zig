const std = @import("std");
const MAX_LIMIT: i64 = 1_500_000;

fn gcdI64(left_input: i64, right_input: i64) i64 {
    var left = left_input;
    var right = right_input;
    while (right != 0) {
        const remainder = @mod(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

export fn problem75(limit: i64) i64 {
    if (limit > MAX_LIMIT) return -1;
    if (limit < 0) return 0;
    const bound: usize = @intCast(limit);
    const frequency = std.heap.page_allocator.alloc(u8, bound + 1) catch return -1;
    defer std.heap.page_allocator.free(frequency);
    @memset(frequency, 0);
    var m: i64 = 2;
    while (2 * m * (m + 1) <= limit) : (m += 1) {
        var n = @mod(m, 2) + 1;
        while (n < m) : (n += 2) {
            if (gcdI64(m, n) != 1) continue;
            const primitive_perimeter = 2 * m * (m + n);
            var perimeter = primitive_perimeter;
            while (perimeter <= limit) : (perimeter += primitive_perimeter) {
                const index: usize = @intCast(perimeter);
                if (frequency[index] < 2) frequency[index] += 1;
            }
        }
    }
    var unique: i64 = 0;
    for (1..bound + 1) |perimeter| {
        if (frequency[perimeter] == 1) unique += 1;
    }
    return unique;
}
