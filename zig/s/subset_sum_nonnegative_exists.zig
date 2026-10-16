/// Nonnegative subset existence with descending dynamic programming.
export fn subset_sum_nonnegative_exists(input: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 65) return -1;
    const values = input[0..length];
    const target = values[0];
    if (target < 0 or target > 4096) return -1;
    for (values[1..]) |item| {
        if (item < 0 or item > 4096) return -1;
    }

    var reachable: [4097]bool = @splat(false);
    reachable[0] = true;
    for (values[1..]) |item| {
        var sum = target;
        while (sum >= item) : (sum -= 1) {
            if (reachable[@intCast(sum - item)]) reachable[@intCast(sum)] = true;
        }
    }
    return if (reachable[@intCast(target)]) 1 else 0;
}
