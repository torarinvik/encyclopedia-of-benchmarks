const std = @import("std");

const MAX_VERTICES: i64 = 256;
const MAX_PARSEABLE_LENGTH: usize = 258;

fn descending(_: void, left: i64, right: i64) bool {
    return left > right;
}

export fn erdos_gallai_graphical_sequence(
    input: [*c]const i64,
    length: usize,
) i64 {
    if (input == null or length == 0 or length > MAX_PARSEABLE_LENGTH) return -1;
    const count_value = input[0];
    if (count_value < 0 or count_value > MAX_VERTICES) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 1) return -1;

    var degrees: [256]i64 = @splat(0);
    var degree_sum: i64 = 0;
    for (0..count) |index| {
        const degree = input[index + 1];
        if (degree < 0 or degree >= count_value) return -1;
        degrees[index] = degree;
        degree_sum += degree;
    }
    if (count == 0) return 1;
    if (@rem(degree_sum, 2) != 0) return 0;

    std.mem.sort(i64, degrees[0..count], {}, descending);
    var prefix: [257]i64 = @splat(0);
    for (0..count) |index| {
        prefix[index + 1] = prefix[index] + degrees[index];
    }

    var k: usize = 1;
    while (k <= count) : (k += 1) {
        var low = k;
        var high = count;
        while (low < high) {
            const middle = low + (high - low) / 2;
            if (degrees[middle] >= @as(i64, @intCast(k))) {
                low = middle + 1;
            } else {
                high = middle;
            }
        }
        const boundary = low;
        const k_value: i64 = @intCast(k);
        const right_side = k_value * (k_value - 1)
            + k_value * @as(i64, @intCast(boundary - k))
            + prefix[count] - prefix[boundary];
        if (prefix[k] > right_side) return 0;
    }
    return 1;
}
