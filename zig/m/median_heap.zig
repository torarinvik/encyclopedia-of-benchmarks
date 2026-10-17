const MAX_OPERATIONS = 256;
const MAX_INPUT_LENGTH = 514;
const MAX_LIVE_VALUES = 64;
const NIL_SENTINEL: i64 = -9_223_372_036_854_775_808;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}
fn pushMax(heap: *[MAX_LIVE_VALUES]i32, count: *usize, value: i32) void {
    var position = count.*;
    count.* += 1;
    while (position > 0 and heap[(position - 1) / 2] < value) {
        const parent = (position - 1) / 2;
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = value;
}
fn popMax(heap: *[MAX_LIVE_VALUES]i32, count: *usize) i32 {
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
fn pushMin(heap: *[MAX_LIVE_VALUES]i32, count: *usize, value: i32) void {
    var position = count.*;
    count.* += 1;
    while (position > 0 and heap[(position - 1) / 2] > value) {
        const parent = (position - 1) / 2;
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = value;
}
fn popMin(heap: *[MAX_LIVE_VALUES]i32, count: *usize) i32 {
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

export fn median_heap(input_opt: ?[*]const i64, length: usize,
                      output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const operation_count_value = input[0];
    if (operation_count_value < 0 or operation_count_value > MAX_OPERATIONS or
        length != 1 + 2 * @as(usize, @intCast(operation_count_value))) return -1;
    const operation_count: usize = @intCast(operation_count_value);
    var lower: [MAX_LIVE_VALUES]i32 = @splat(0);
    var upper: [MAX_LIVE_VALUES]i32 = @splat(0);
    var lower_count: usize = 0;
    var upper_count: usize = 0;
    var results: [MAX_OPERATIONS]i64 = @splat(0);
    for (0..operation_count) |i| {
        const opcode = input[1 + 2 * i];
        const argument = input[2 + 2 * i];
        if (opcode == 0) {
            if (argument < -2147483648 or argument > 2147483647 or lower_count + upper_count >= MAX_LIVE_VALUES) return -1;
            const value: i32 = @intCast(argument);
            if (lower_count == 0) {
                pushMax(&lower, &lower_count, value);
            } else if (value < lower[0]) {
                pushMax(&lower, &lower_count, value);
                if (lower_count - upper_count > 1) pushMin(&upper, &upper_count, popMax(&lower, &lower_count));
            } else {
                pushMin(&upper, &upper_count, value);
                if (lower_count < upper_count) pushMax(&lower, &lower_count, popMin(&upper, &upper_count));
            }
            results[i] = NIL_SENTINEL;
        } else if (opcode >= 1 and opcode <= 4) {
            if (argument != 0) return -1;
            if (opcode == 1) {
                results[i] = if (lower_count > 0) lower[0] else NIL_SENTINEL;
            } else if (opcode == 2) {
                if (lower_count == 0) {
                    results[i] = NIL_SENTINEL;
                } else {
                    results[i] = popMax(&lower, &lower_count);
                    if (lower_count < upper_count) pushMax(&lower, &lower_count, popMin(&upper, &upper_count));
                }
            } else if (opcode == 3) {
                results[i] = @intCast(lower_count + upper_count);
            } else {
                results[i] = if (lower_count == 0) 1 else 0;
            }
        } else return -1;
    }
    const output_bytes = operation_count * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..operation_count) |i| storeI64Le(output, 8 * i, results[i]);
    return @intCast(output_bytes);
}
