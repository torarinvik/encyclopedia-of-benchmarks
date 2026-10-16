const MAX_COUNT: usize = 64;
const VALUE_LIMIT: i64 = 1_000_000;

fn heapPush(heap: []i64, size: *usize, is_max: bool, value: i64) void {
    var index = size.*;
    size.* += 1;
    heap[index] = value;
    while (index > 0) {
        const parent = (index - 1) / 2;
        const ordered = if (is_max) heap[parent] >= heap[index] else heap[parent] <= heap[index];
        if (ordered) break;
        const temporary = heap[parent];
        heap[parent] = heap[index];
        heap[index] = temporary;
        index = parent;
    }
}

fn heapPop(heap: []i64, size: *usize, is_max: bool) i64 {
    const result = heap[0];
    size.* -= 1;
    heap[0] = heap[size.*];
    var index: usize = 0;
    while (true) {
        const left = 2 * index + 1;
        const right = left + 1;
        var best = index;
        if (left < size.* and (if (is_max) heap[left] > heap[best] else heap[left] < heap[best])) best = left;
        if (right < size.* and (if (is_max) heap[right] > heap[best] else heap[right] < heap[best])) best = right;
        if (best == index) break;
        const temporary = heap[index];
        heap[index] = heap[best];
        heap[best] = temporary;
        index = best;
    }
    return result;
}

fn writeF64Le(output: [*]u8, position: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[position + byte] = @truncate(bits >> @intCast(8 * byte));
    }
}

export fn median_finder(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_COUNT + 1) return -1;
    const values = input.?[0..length];
    const count_value = values[0];
    if (count_value < 1 or count_value > MAX_COUNT or length != @as(usize, @intCast(count_value)) + 1) return -1;
    const count: usize = @intCast(count_value);
    for (values[1..]) |value| {
        if (value < -VALUE_LIMIT or value > VALUE_LIMIT) return -1;
    }
    const required = count * 8;
    if (output == null or output_capacity < required) return -2;

    var lower: [32]i64 = @splat(0);
    var upper: [32]i64 = @splat(0);
    var lower_size: usize = 0;
    var upper_size: usize = 0;
    for (values[1..], 0..) |value, index| {
        if (lower_size == 32 and lower_size > upper_size and value <= lower[0]) {
            heapPush(upper[0..], &upper_size, false, heapPop(lower[0..], &lower_size, true));
            heapPush(lower[0..], &lower_size, true, value);
        } else {
            if (lower_size == 0 or value <= lower[0]) heapPush(lower[0..], &lower_size, true, value)
            else heapPush(upper[0..], &upper_size, false, value);
            if (lower_size > upper_size + 1) heapPush(upper[0..], &upper_size, false, heapPop(lower[0..], &lower_size, true))
            else if (upper_size > lower_size) heapPush(lower[0..], &lower_size, true, heapPop(upper[0..], &upper_size, false));
        }
        const median: f64 = if (lower_size == upper_size)
            (@as(f64, @floatFromInt(lower[0])) + @as(f64, @floatFromInt(upper[0]))) / 2.0
        else
            @floatFromInt(lower[0]);
        writeF64Le(output.?, index * 8, median);
    }
    return @intCast(required);
}
