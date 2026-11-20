const MAX_Q: usize = 63;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 128;
const VALUE_OFFSET: i64 = 100;
const VALUE_COUNT: usize = 201;

fn entryLess(left: usize, right: usize, values: *const [MAX_Q]i64) bool {
    return values[left] < values[right] or (values[left] == values[right] and left < right);
}

fn heapPush(heap: *[MAX_Q]usize, size: *usize, item: usize, values: *const [MAX_Q]i64) void {
    var at = size.*;
    size.* += 1;
    while (at > 0) {
        const parent = (at - 1) / 2;
        if (!entryLess(item, heap[parent], values)) break;
        heap[at] = heap[parent];
        at = parent;
    }
    heap[at] = item;
}

fn heapPop(heap: *[MAX_Q]usize, size: *usize, values: *const [MAX_Q]i64) usize {
    const result = heap[0];
    size.* -= 1;
    if (size.* == 0) return result;
    const last = heap[size.*];
    var at: usize = 0;
    while (true) {
        var child = 2 * at + 1;
        if (child >= size.*) break;
        if (child + 1 < size.* and entryLess(heap[child + 1], heap[child], values)) child += 1;
        if (!entryLess(heap[child], last, values)) break;
        heap[at] = heap[child];
        at = child;
    }
    heap[at] = last;
    return result;
}

fn normalize(live: *[MAX_Q]usize, live_size: *usize,
    deleted: *[MAX_Q]usize, deleted_size: *usize, values: *const [MAX_Q]i64) void {
    while (live_size.* > 0 and deleted_size.* > 0 and live[0] == deleted[0]) {
        _ = heapPop(live, live_size, values);
        _ = heapPop(deleted, deleted_size, values);
    }
}

export fn erasable_priority_queue_trace(input: [*c]const i64, length: usize) i64 {
    if (input == null or length == 0 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const operation_count_value = input[0];
    if (operation_count_value < 0 or operation_count_value > 63) return -1;
    const operation_count: usize = @intCast(operation_count_value);
    if (length != 1 + 2 * operation_count) return -1;

    var values: [MAX_Q]i64 = @splat(0);
    var counts: [VALUE_COUNT]usize = @splat(0);
    var active: [MAX_Q]bool = @splat(false);
    var live: [MAX_Q]usize = @splat(0);
    var deleted: [MAX_Q]usize = @splat(0);
    var live_size: usize = 0;
    var deleted_size: usize = 0;
    var inserted: usize = 0;
    var score: i64 = 0;

    for (0..operation_count) |operation| {
        const opcode_value = input[1 + 2 * operation];
        const operand_value = input[2 + 2 * operation];
        if (opcode_value < 0 or opcode_value > 3 or operand_value < -VALUE_OFFSET or operand_value > VALUE_OFFSET) return -1;
        const opcode: usize = @intCast(opcode_value);
        const value_index: usize = @intCast(operand_value + VALUE_OFFSET);
        normalize(&live, &live_size, &deleted, &deleted_size, &values);

        var response: i64 = 0;
        if (opcode == 0) {
            const id = inserted;
            inserted += 1;
            values[id] = operand_value;
            active[id] = true;
            counts[value_index] += 1;
            heapPush(&live, &live_size, id, &values);
            normalize(&live, &live_size, &deleted, &deleted_size, &values);
        } else if (opcode == 1) {
            if (counts[value_index] == 0) return -1;
            var found = false;
            var id: usize = 0;
            for (0..inserted) |candidate| {
                if (active[candidate] and values[candidate] == operand_value) {
                    id = candidate;
                    found = true;
                    break;
                }
            }
            if (!found) return -1;
            active[id] = false;
            counts[value_index] -= 1;
            heapPush(&deleted, &deleted_size, id, &values);
            response = 1;
            normalize(&live, &live_size, &deleted, &deleted_size, &values);
        } else if (opcode == 2) {
            if (operand_value != 0) return -1;
            response = if (live_size == 0) -101 else values[live[0]];
        } else {
            if (operand_value != 0 or live_size == 0) return -1;
            const id = heapPop(&live, &live_size, &values);
            active[id] = false;
            counts[@intCast(values[id] + VALUE_OFFSET)] -= 1;
            response = values[id];
        }
        const token = opcode_value * 202 + response + 101;
        score += (@as(i64, @intCast(operation)) + 1) * token;
    }
    return score;
}
