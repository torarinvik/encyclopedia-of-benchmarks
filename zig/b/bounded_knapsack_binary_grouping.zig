const MAX_TYPES: usize = 16;
const MAX_CAPACITY: usize = 64;
const MAX_INPUT: usize = 51;

pub export fn bounded_knapsack_binary_grouping(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const type_count_value = input[0];
    const capacity_value = input[1];
    if (type_count_value < 0 or type_count_value > @as(i64, @intCast(MAX_TYPES))
        or capacity_value < 0 or capacity_value > @as(i64, @intCast(MAX_CAPACITY))) return -1;
    const type_count: usize = @intCast(type_count_value);
    const capacity: usize = @intCast(capacity_value);
    if (length != 2 + 3 * type_count) return -1;
    for (0..type_count) |item| {
        const weight = input[2 + 3 * item];
        const value = input[3 + 3 * item];
        const count = input[4 + 3 * item];
        if (weight < 1 or weight > 16 or value < 0 or value > 100 or count < 0 or count > 16) return -1;
    }

    var best: [MAX_CAPACITY + 1]i64 = @splat(0);
    for (0..type_count) |item| {
        const weight: usize = @intCast(input[2 + 3 * item]);
        const value = input[3 + 3 * item];
        var remaining: usize = @intCast(input[4 + 3 * item]);
        var bundle_size: usize = 1;
        while (remaining > 0) {
            const copies = @min(bundle_size, remaining);
            const bundle_weight = weight * copies;
            const bundle_value = value * @as(i64, @intCast(copies));
            if (bundle_weight <= capacity) {
                var limit = capacity;
                while (limit >= bundle_weight) {
                    const candidate = best[limit - bundle_weight] + bundle_value;
                    best[limit] = @max(best[limit], candidate);
                    if (limit == bundle_weight) break;
                    limit -= 1;
                }
            }
            remaining -= copies;
            bundle_size *= 2;
        }
    }
    return best[capacity];
}
