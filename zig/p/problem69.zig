const std = @import("std");
const MAX_LIMIT: i64 = 1_000_000;

pub export fn problem69(inclusive_limit: i64) i64 {
    if (inclusive_limit < 1 or inclusive_limit > MAX_LIMIT) return -1;
    const limit: usize = @intCast(inclusive_limit);
    const phi = std.heap.page_allocator.alloc(u32, limit + 1) catch return -1;
    defer std.heap.page_allocator.free(phi);
    for (0..limit + 1) |value| phi[value] = @intCast(value);
    var number: usize = 2;
    while (number <= limit) : (number += 1) {
        if (phi[number] != number) continue;
        phi[number] -= 1;
        var multiple = number * 2;
        while (multiple <= limit) : (multiple += number) {
            phi[multiple] = (phi[multiple] / @as(u32, @intCast(number))) * @as(u32, @intCast(number - 1));
        }
    }
    var answer: usize = 1;
    for (1..limit + 1) |candidate| {
        const left: u64 = @as(u64, @intCast(candidate)) * phi[answer];
        const right: u64 = @as(u64, @intCast(answer)) * phi[candidate];
        if (left > right) answer = candidate;
    }
    return @intCast(answer);
}
