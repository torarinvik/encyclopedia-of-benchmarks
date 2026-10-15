/// Find the cycle entrance induced by the duplicate value.
export fn find_duplicate_number(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 100001) return -1;
    const maximum_value = length - 1;
    for (0..length) |index| {
        if (values[index] < 1 or @as(u64, @intCast(values[index])) > maximum_value) return -1;
    }

    var slow: usize = @intCast(values[0]);
    var fast = slow;
    while (true) {
        slow = @intCast(values[slow]);
        fast = @intCast(values[@as(usize, @intCast(values[fast]))]);
        if (slow == fast) break;
    }

    slow = @intCast(values[0]);
    while (slow != fast) {
        slow = @intCast(values[slow]);
        fast = @intCast(values[fast]);
    }
    return @intCast(slow);
}
