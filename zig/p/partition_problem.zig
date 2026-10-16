/// Equal-sum two-way partition using bottom-up subset-sum reachability.
const MAX_ITEMS: usize = 16;
const MAX_TOTAL: usize = 1024;

export fn partition_problem(input: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_ITEMS) return -1;
    const values = input[0..length];
    var total: i64 = 0;
    for (values) |value| {
        if (value < 0 or value > 256 or total > 1024 - value) return -1;
        total += value;
    }
    if (@mod(total, 2) != 0) return 0;
    const target: usize = @intCast(@divTrunc(total, 2));
    var reachable: [MAX_TOTAL + 1]bool = @splat(false);
    reachable[0] = true;
    for (values) |raw_value| {
        const value: usize = @intCast(raw_value);
        if (value <= target) {
            var sum = target;
            while (sum >= value) : (sum -= 1) {
                if (reachable[sum - value]) reachable[sum] = true;
                if (sum == value) break;
            }
        }
    }
    return if (reachable[target]) 1 else 0;
}
