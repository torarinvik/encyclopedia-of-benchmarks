/// Count indexed signed subsets that reach the requested sum.
export fn subset_sum_count(input: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 25) return -1;
    const target = input[0];
    if (target < -6144 or target > 6144) return -1;
    for (1..length) |index| {
        if (input[index] < -256 or input[index] > 256) return -1;
    }
    var ways: [12289]i64 = @splat(0);
    ways[6144] = 1;
    var low: i64 = 0;
    var high: i64 = 0;
    for (1..length) |index| {
        const value = input[index];
        if (value > 0) {
            var sum = high;
            while (sum >= low) : (sum -= 1) {
                ways[@intCast(sum + value + 6144)] += ways[@intCast(sum + 6144)];
            }
            high += value;
        } else if (value < 0) {
            var sum = low;
            while (sum <= high) : (sum += 1) {
                ways[@intCast(sum + value + 6144)] += ways[@intCast(sum + 6144)];
            }
            low += value;
        } else {
            var sum = low;
            while (sum <= high) : (sum += 1) ways[@intCast(sum + 6144)] *= 2;
        }
    }
    return ways[@intCast(target + 6144)];
}
