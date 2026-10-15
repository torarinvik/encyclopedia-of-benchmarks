const std = @import("std");
const INVALID_RESULT: i64 = std.math.minInt(i64);

export fn max_product_subarray(values: [*]const i64, length: usize) i64 {
    if (length > 9) return INVALID_RESULT;
    if (length == 0) return 0;
    if (values[0] < -10 or values[0] > 10) return INVALID_RESULT;
    var max_now = values[0];
    var min_now = values[0];
    var max_product = values[0];
    for (1..length) |i| {
        const value = values[i];
        if (value < -10 or value > 10) return INVALID_RESULT;
        if (value < 0) {
            const temp = max_now;
            max_now = min_now;
            min_now = temp;
        }
        max_now = @max(value, max_now * value);
        min_now = @min(value, min_now * value);
        max_product = @max(max_product, max_now);
    }
    return max_product;
}
