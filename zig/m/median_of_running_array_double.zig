const std = @import("std");

const MAX_COUNT = 64;
const MAX_INPUT_LENGTH = 66;

fn lessDouble(left: f64, right: f64) bool {
    if (left < right) return true;
    if (left == 0.0 and right == 0.0) return @as(u64, @bitCast(left)) >> 63 != 0 and @as(u64, @bitCast(right)) >> 63 == 0;
    return false;
}
fn pushMax(heap: *[MAX_COUNT]f64, count: *usize, value: f64) void {
    var position = count.*; count.* += 1;
    while (position > 0 and lessDouble(heap[(position - 1) / 2], value)) {
        const parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent;
    }
    heap[position] = value;
}
fn popMax(heap: *[MAX_COUNT]f64, count: *usize) f64 {
    const result = heap[0]; count.* -= 1; const value = heap[count.*];
    if (count.* == 0) return result;
    var position: usize = 0;
    while (2 * position + 1 < count.*) {
        var child = 2 * position + 1;
        if (child + 1 < count.* and lessDouble(heap[child], heap[child + 1])) child += 1;
        if (!lessDouble(value, heap[child])) break;
        heap[position] = heap[child]; position = child;
    }
    heap[position] = value; return result;
}
fn pushMin(heap: *[MAX_COUNT]f64, count: *usize, value: f64) void {
    var position = count.*; count.* += 1;
    while (position > 0 and lessDouble(value, heap[(position - 1) / 2])) {
        const parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent;
    }
    heap[position] = value;
}
fn popMin(heap: *[MAX_COUNT]f64, count: *usize) f64 {
    const result = heap[0]; count.* -= 1; const value = heap[count.*];
    if (count.* == 0) return result;
    var position: usize = 0;
    while (2 * position + 1 < count.*) {
        var child = 2 * position + 1;
        if (child + 1 < count.* and lessDouble(heap[child + 1], heap[child])) child += 1;
        if (!lessDouble(heap[child], value)) break;
        heap[position] = heap[child]; position = child;
    }
    heap[position] = value; return result;
}

export fn median_of_running_array_double(input_opt: ?[*]const f64, length: usize,
                                         output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const count_value = input[0];
    if (!std.math.isFinite(count_value) or count_value < 1.0 or count_value > MAX_COUNT or @trunc(count_value) != count_value or
        length != 1 + @as(usize, @intFromFloat(count_value))) return -1;
    const count: usize = @intFromFloat(count_value);
    var lower: [MAX_COUNT]f64 = @splat(0.0); var upper: [MAX_COUNT]f64 = @splat(0.0); var medians: [MAX_COUNT]f64 = @splat(0.0);
    var lower_count: usize = 0; var upper_count: usize = 0;
    for (0..count) |i| {
        const sample = input[i + 1];
        if (!std.math.isFinite(sample) or sample < -1_000_000.0 or sample > 1_000_000.0) return -1;
        if (upper_count > 0 and lessDouble(sample, upper[0])) pushMax(&lower, &lower_count, sample)
        else pushMin(&upper, &upper_count, sample);
        if (lower_count > upper_count + 1) pushMin(&upper, &upper_count, popMax(&lower, &lower_count))
        else if (upper_count > lower_count + 1) pushMax(&lower, &lower_count, popMin(&upper, &upper_count));
        if (lower_count > upper_count) medians[i] = lower[0]
        else if (upper_count > lower_count) medians[i] = upper[0]
        else medians[i] = (lower[0] + upper[0]) / 2.0;
    }
    if (output_opt == null or capacity < count) return -2;
    const output = output_opt.?;
    for (0..count) |i| output[i] = medians[i];
    return @intCast(count);
}
