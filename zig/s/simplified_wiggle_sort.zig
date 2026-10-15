const std = @import("std");
const MAX_ARRAY_LENGTH: usize = 4096;

export fn simplified_wiggle_sort(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length > MAX_ARRAY_LENGTH) return -1;
    var values: [MAX_ARRAY_LENGTH]i64 = @splat(0);
    var ordered: [MAX_ARRAY_LENGTH]i64 = @splat(0);
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
    var smaller: usize = 0;
    var greater: isize = @intCast(length - 1 - (length % 2));
    for (0..length) |i| {
        if (values[i] > median) {
            ordered[@intCast(greater)] = values[i];
            greater -= 2;
        } else if (smaller < length) {
            ordered[smaller] = values[i];
            smaller += 2;
        } else {
            ordered[@intCast(greater)] = values[i];
            greater -= 2;
        }
    }
    for (0..length) |i| {
        const bits: u32 = @bitCast(@as(i32, @intCast(ordered[i])));
        for (0..4) |byte| output[i * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(length);
}
