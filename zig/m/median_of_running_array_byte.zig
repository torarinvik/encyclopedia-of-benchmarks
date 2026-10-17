const MAX_COUNT = 64;
const MAX_INPUT_LENGTH = 66;

fn pushMax(heap: *[MAX_COUNT]i32, count: *usize, value: i32) void {
    var position = count.*;
    count.* += 1;
    while (position > 0 and heap[(position - 1) / 2] < value) {
        const parent = (position - 1) / 2;
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = value;
}
fn popMax(heap: *[MAX_COUNT]i32, count: *usize) i32 {
    const result = heap[0];
    count.* -= 1;
    const value = heap[count.*];
    if (count.* == 0) return result;
    var position: usize = 0;
    while (2 * position + 1 < count.*) {
        var child = 2 * position + 1;
        if (child + 1 < count.* and heap[child + 1] > heap[child]) child += 1;
        if (heap[child] <= value) break;
        heap[position] = heap[child];
        position = child;
    }
    heap[position] = value;
    return result;
}
fn pushMin(heap: *[MAX_COUNT]i32, count: *usize, value: i32) void {
    var position = count.*;
    count.* += 1;
    while (position > 0 and heap[(position - 1) / 2] > value) {
        const parent = (position - 1) / 2;
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = value;
}
fn popMin(heap: *[MAX_COUNT]i32, count: *usize) i32 {
    const result = heap[0];
    count.* -= 1;
    const value = heap[count.*];
    if (count.* == 0) return result;
    var position: usize = 0;
    while (2 * position + 1 < count.*) {
        var child = 2 * position + 1;
        if (child + 1 < count.* and heap[child + 1] < heap[child]) child += 1;
        if (heap[child] >= value) break;
        heap[position] = heap[child];
        position = child;
    }
    heap[position] = value;
    return result;
}

export fn median_of_running_array_byte(input_opt: ?[*]const i32, length: usize,
                                       output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const count_value = input[0];
    if (count_value < 1 or count_value > MAX_COUNT or length != 1 + @as(usize, @intCast(count_value))) return -1;
    const count: usize = @intCast(count_value);
    var lower: [MAX_COUNT]i32 = @splat(0);
    var upper: [MAX_COUNT]i32 = @splat(0);
    var medians: [MAX_COUNT]u8 = @splat(0);
    var lower_count: usize = 0;
    var upper_count: usize = 0;
    for (0..count) |i| {
        const sample = input[i + 1];
        if (sample < -128 or sample > 127) return -1;
        if (upper_count > 0 and sample < upper[0]) pushMax(&lower, &lower_count, sample)
        else pushMin(&upper, &upper_count, sample);
        if (lower_count > upper_count + 1) pushMin(&upper, &upper_count, popMax(&lower, &lower_count))
        else if (upper_count > lower_count + 1) pushMax(&lower, &lower_count, popMin(&upper, &upper_count));
        var median: i32 = 0;
        if (lower_count > upper_count) median = lower[0] else if (upper_count > lower_count) median = upper[0] else {
            const sum = lower[0] + upper[0];
            median = if (sum < 0) -((-sum) / 2) else sum / 2;
        }
        medians[i] = @bitCast(@as(i8, @intCast(median)));
    }
    if (output_opt == null or capacity < count) return -2;
    const output = output_opt.?;
    for (0..count) |i| output[i] = medians[i];
    return @intCast(count);
}
