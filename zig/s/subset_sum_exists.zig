/// Decide whether a signed integer subset reaches the requested sum.
export fn subset_sum_exists(input: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 25) return -1;
    const target = input[0];
    if (target < -6144 or target > 6144) return -1;
    for (1..length) |index| {
        if (input[index] < -256 or input[index] > 256) return -1;
    }
    var reachable: [12289]bool = @splat(false);
    reachable[6144] = true;
    var low: i64 = 0;
    var high: i64 = 0;
    for (1..length) |index| {
        const value = input[index];
        if (value > 0) {
            var sum = high;
            while (sum >= low) : (sum -= 1) {
                if (reachable[@intCast(sum + 6144)]) reachable[@intCast(sum + value + 6144)] = true;
            }
            high += value;
        } else if (value < 0) {
            var sum = low;
            while (sum <= high) : (sum += 1) {
                if (reachable[@intCast(sum + 6144)]) reachable[@intCast(sum + value + 6144)] = true;
            }
            low += value;
        }
    }
    return if (reachable[@intCast(target + 6144)]) 1 else 0;
}
