const std = @import("std");
const MAX_ITEMS: usize = 128;

export fn link_list_sort(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > 2 + MAX_ITEMS) return -1;
    const selector = input[0];
    const count_value = input[1];
    if (selector < 1 or selector > 3 or count_value < 0 or count_value > MAX_ITEMS) return -1;
    const count: usize = @intCast(count_value);
    if (length != 2 + count) return -1;
    var items = [_]i32{0} ** MAX_ITEMS;
    var scratch = [_]i32{0} ** MAX_ITEMS;
    for (0..count) |i| {
        if (input[2 + i] < std.math.minInt(i32) or input[2 + i] > std.math.maxInt(i32)) return -1;
        items[i] = @intCast(input[2 + i]);
    }
    if (selector == 1) {
        var width: usize = 1;
        while (width < count) : (width *= 2) {
            var start: usize = 0;
            while (start < count) {
                const middle = @min(start + width, count);
                const finish = @min(middle + width, count);
                var left = start;
                var right = middle;
                var out_index = start;
                while (left < middle and right < finish) {
                    if (items[left] <= items[right]) { scratch[out_index] = items[left]; left += 1; }
                    else { scratch[out_index] = items[right]; right += 1; }
                    out_index += 1;
                }
                while (left < middle) : (left += 1) { scratch[out_index] = items[left]; out_index += 1; }
                while (right < finish) : (right += 1) { scratch[out_index] = items[right]; out_index += 1; }
                start = finish;
            }
            @memcpy(items[0..count], scratch[0..count]);
        }
    } else if (selector == 2) {
        for (1..count) |i| {
            const value = items[i];
            var j = i;
            while (j > 0 and items[j - 1] > value) { items[j] = items[j - 1]; j -= 1; }
            items[j] = value;
        }
    } else {
        var start = count / 2;
        while (start > 0) {
            start -= 1;
            var root = start;
            while (root < count / 2) {
                var child = 2 * root + 1;
                if (child + 1 < count and items[child + 1] > items[child]) child += 1;
                if (items[root] >= items[child]) break;
                const value = items[root]; items[root] = items[child]; items[child] = value;
                root = child;
            }
        }
        var end = count;
        while (end > 1) {
            end -= 1;
            const value = items[0]; items[0] = items[end]; items[end] = value;
            var root: usize = 0;
            while (root < end / 2) {
                var child = 2 * root + 1;
                if (child + 1 < end and items[child + 1] > items[child]) child += 1;
                if (items[root] >= items[child]) break;
                const swap_value = items[root]; items[root] = items[child]; items[child] = swap_value;
                root = child;
            }
        }
    }
    const required = 4 * count;
    if (output == null or output_capacity < required) return -2;
    const out: [*]u8 = @ptrCast(output);
    for (0..count) |i| {
        const bits: u32 = @bitCast(items[i]);
        for (0..4) |byte| out[4 * i + byte] = @truncate(bits >> @as(u5, @intCast(8 * byte)));
    }
    return @intCast(required);
}
