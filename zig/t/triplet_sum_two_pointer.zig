fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @intCast((bits >> @intCast(byte * 8)) & 255);
    }
}

fn siftDown(values: []i64, root_start: usize, ending: usize) void {
    var root = root_start;
    while (root < ending / 2) {
        var child = root * 2 + 1;
        if (child + 1 < ending and values[child] < values[child + 1]) child += 1;
        if (values[root] >= values[child]) break;
        std.mem.swap(i64, &values[root], &values[child]);
        root = child;
    }
}

fn heapSort(values: []i64) void {
    const length = values.len;
    var start = length / 2;
    while (start > 0) {
        start -= 1;
        siftDown(values, start, length);
    }
    var ending = length;
    while (ending > 1) {
        ending -= 1;
        std.mem.swap(i64, &values[0], &values[ending]);
        siftDown(values, 0, ending);
    }
}

const std = @import("std");

pub export fn triplet_sum_two_pointer(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    const max_items: usize = 1024;
    if (input == null or length < 1 or length > max_items + 1) return -1;
    const target = input[0];
    if (target < -3_000_000 or target > 3_000_000) return -1;
    const item_count = length - 1;
    var storage: [max_items]i64 = @splat(0);
    for (0..item_count) |index| {
        const value = input[index + 1];
        if (value < -1_000_000 or value > 1_000_000) return -1;
        storage[index] = value;
    }
    if (output_capacity < 24 or output == null) return -2;
    heapSort(storage[0..item_count]);

    var result = [_]i64{ 0, 0, 0 };
    if (item_count >= 3) {
        for (0..item_count - 2) |first| {
            var left = first + 1;
            var right = item_count - 1;
            while (left < right) {
                const sum = storage[first] + storage[left] + storage[right];
                if (sum == target) {
                    result = .{ storage[first], storage[left], storage[right] };
                    for (0..3) |index| putI64Le(output, index * 8, result[index]);
                    return 3;
                }
                if (sum < target) {
                    left += 1;
                } else {
                    right -= 1;
                }
            }
        }
    }
    for (0..3) |index| putI64Le(output, index * 8, result[index]);
    return 3;
}
