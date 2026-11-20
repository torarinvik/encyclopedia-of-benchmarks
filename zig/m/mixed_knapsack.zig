const MAX_TYPES: usize = 16;
const MAX_CAPACITY: usize = 64;
const MAX_INPUT: usize = 67;

pub export fn mixed_knapsack(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const type_count_value = input[0];
    const capacity_value = input[1];
    if (type_count_value < 0 or type_count_value > @as(i64, @intCast(MAX_TYPES))
        or capacity_value < 0 or capacity_value > @as(i64, @intCast(MAX_CAPACITY))) return -1;
    const type_count: usize = @intCast(type_count_value);
    const capacity: usize = @intCast(capacity_value);
    if (length != 2 + 4 * type_count) return -1;
    for (0..type_count) |item| {
        const mode = input[2 + 4 * item];
        const weight = input[3 + 4 * item];
        const value = input[4 + 4 * item];
        const limit = input[5 + 4 * item];
        if (mode < 0 or mode > 2 or weight < 1 or weight > 16 or value < 0 or value > 100) return -1;
        if ((mode == 0 and limit != 1) or (mode == 1 and limit != 0)
            or (mode == 2 and (limit < 0 or limit > 16))) return -1;
    }

    var best: [MAX_CAPACITY + 1]i64 = @splat(0);
    for (0..type_count) |item| {
        const mode = input[2 + 4 * item];
        const weight: usize = @intCast(input[3 + 4 * item]);
        const value = input[4 + 4 * item];
        if (mode == 0) {
            var cap = capacity;
            while (cap >= weight) {
                best[cap] = @max(best[cap], best[cap - weight] + value);
                if (cap == weight) break;
                cap -= 1;
            }
        } else if (mode == 1) {
            var cap = weight;
            while (cap <= capacity) : (cap += 1) {
                best[cap] = @max(best[cap], best[cap - weight] + value);
            }
        } else {
            var remaining: usize = @intCast(input[5 + 4 * item]);
            var bundle_size: usize = 1;
            while (remaining > 0) {
                const copies = @min(bundle_size, remaining);
                const bundle_weight = copies * weight;
                const bundle_value = @as(i64, @intCast(copies)) * value;
                if (bundle_weight <= capacity) {
                    var cap = capacity;
                    while (cap >= bundle_weight) {
                        best[cap] = @max(best[cap], best[cap - bundle_weight] + bundle_value);
                        if (cap == bundle_weight) break;
                        cap -= 1;
                    }
                }
                remaining -= copies;
                bundle_size *= 2;
            }
        }
    }
    return best[capacity];
}
