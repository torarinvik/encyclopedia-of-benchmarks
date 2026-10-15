const std = @import("std");
const MAX_ARRAY_LENGTH: usize = 4096;

export fn wiggle_sort_strict(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length > MAX_ARRAY_LENGTH) return -1;
    var values: [MAX_ARRAY_LENGTH]i64 = @splat(0);
    for (0..length) |i| {
        if (input[i] < std.math.minInt(i32) or input[i] > std.math.maxInt(i32)) return -1;
        values[i] = input[i];
    }
    const bytes = length * 4;
    if (output_capacity < bytes) return -2;
    if (length == 0) return 0;

    var low: isize = 0;
    var high: isize = @intCast(length - 1);
    const target: usize = length / 2;
    while (low < high) {
        var left = low;
        var right = high;
        const pivot = values[@intCast(@divTrunc(left + right + 1, 2))];
        while (left <= right) {
            while (left <= right and values[@intCast(left)] < pivot) left += 1;
            while (left <= right and values[@intCast(right)] > pivot) right -= 1;
            if (left <= right) {
                const temporary = values[@intCast(left)];
                values[@intCast(left)] = values[@intCast(right)];
                values[@intCast(right)] = temporary;
                left += 1;
                right -= 1;
            }
        }
        if (@as(isize, @intCast(target)) <= right) high = right
        else if (@as(isize, @intCast(target)) >= left) low = left
        else break;
    }
    const median = values[target];
    var median_count: usize = 0;
    var smallest_value = values[0];
    for (0..length) |index| {
        if (values[index] == median) median_count += 1;
        if (values[index] < smallest_value) smallest_value = values[index];
    }
    const maximum_medians = (length + 1) / 2;
    if (median_count > maximum_medians
        or (length % 2 == 1 and median_count == maximum_medians and smallest_value != median)) return -1;

    var less_count: isize = 0;
    var j: isize = 0;
    var k: isize = @intCast(length - 1);
    const modulus: isize = @as(isize, @intCast(length)) + 1 - @as(isize, @intCast(length % 2));
    while (j <= k) {
        const mapped_j = @as(usize, @intCast(@mod(2 * j + 1, modulus)));
        if (values[mapped_j] > median) {
            const mapped_i = @as(usize, @intCast(@mod(2 * less_count + 1, modulus)));
            const temporary = values[mapped_j];
            values[mapped_j] = values[mapped_i];
            values[mapped_i] = temporary;
            less_count += 1;
            j += 1;
        } else if (values[mapped_j] < median) {
            const mapped_k = @as(usize, @intCast(@mod(2 * k + 1, modulus)));
            const temporary = values[mapped_j];
            values[mapped_j] = values[mapped_k];
            values[mapped_k] = temporary;
            k -= 1;
        } else {
            j += 1;
        }
    }
    for (0..length) |i| {
        const bits: u32 = @bitCast(@as(i32, @intCast(values[i])));
        for (0..4) |byte| output[i * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(length);
}
