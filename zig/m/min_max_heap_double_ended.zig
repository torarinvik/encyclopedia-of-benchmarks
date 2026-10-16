const MAX_HEAP_SIZE: usize = 192;
const MAX_INITIAL: usize = 64;
const MAX_OPERATIONS: usize = 128;
const INVALID_RESULT: i64 = -1;
const CAPACITY_RESULT: i64 = -2;

fn isMinLevel(index: usize) bool {
    var value = index + 1;
    var depth: usize = 0;
    while (value > 1) : (depth += 1) { value >>= 1; }
    return depth % 2 == 0;
}

fn swapValues(heap: *[MAX_HEAP_SIZE]i64, left: usize, right: usize) void {
    const temporary = heap[left];
    heap[left] = heap[right];
    heap[right] = temporary;
}

fn bestDescendant(heap: *[MAX_HEAP_SIZE]i64, count: usize, index: usize, find_min: bool) ?usize {
    var best: ?usize = null;
    for (0..6) |offset| {
        const candidate = if (offset < 2) 2 * index + 1 + offset else 4 * index + 1 + offset;
        if (candidate >= count) break;
        if (best == null or (if (find_min) heap[candidate] < heap[best.?] else heap[candidate] > heap[best.?])) best = candidate;
    }
    return best;
}

fn pushDown(heap: *[MAX_HEAP_SIZE]i64, count: usize, start: usize, find_min: bool) void {
    var index = start;
    while (index < count) {
        const best = bestDescendant(heap, count, index, find_min) orelse return;
        const grandchild = best > 2 and (best - 3) / 4 == index;
        const improves = if (find_min) heap[best] < heap[index] else heap[best] > heap[index];
        if (grandchild) {
            if (!improves) return;
            swapValues(heap, best, index);
            const parent = (best - 1) / 2;
            const violation = if (find_min) heap[best] > heap[parent] else heap[best] < heap[parent];
            if (violation) swapValues(heap, best, parent);
            index = best;
        } else {
            if (improves) swapValues(heap, best, index);
            return;
        }
    }
}

fn pushUpMin(heap: *[MAX_HEAP_SIZE]i64, start: usize) void {
    var index = start;
    while (index > 2) {
        const grandparent = (index - 3) / 4;
        if (heap[index] >= heap[grandparent]) return;
        swapValues(heap, index, grandparent);
        index = grandparent;
    }
}

fn pushUpMax(heap: *[MAX_HEAP_SIZE]i64, start: usize) void {
    var index = start;
    while (index > 2) {
        const grandparent = (index - 3) / 4;
        if (heap[index] <= heap[grandparent]) return;
        swapValues(heap, index, grandparent);
        index = grandparent;
    }
}

fn pushUp(heap: *[MAX_HEAP_SIZE]i64, index: usize) void {
    if (index == 0) return;
    const parent = (index - 1) / 2;
    if (isMinLevel(index)) {
        if (heap[index] > heap[parent]) {
            swapValues(heap, index, parent);
            pushUpMax(heap, parent);
        } else pushUpMin(heap, index);
    } else if (heap[index] < heap[parent]) {
        swapValues(heap, index, parent);
        pushUpMin(heap, parent);
    } else pushUpMax(heap, index);
}

fn addValue(heap: *[MAX_HEAP_SIZE]i64, count: *usize, value: i64) void {
    const index = count.*;
    count.* += 1;
    heap[index] = value;
    pushUp(heap, index);
}

fn maxIndex(heap: *[MAX_HEAP_SIZE]i64, count: usize) usize {
    if (count < 2) return 0;
    if (count == 2) return 1;
    return if (heap[1] > heap[2]) 1 else 2;
}

fn extractAt(heap: *[MAX_HEAP_SIZE]i64, count: *usize, index: usize) i64 {
    const result = heap[index];
    count.* -= 1;
    if (index != count.*) heap[index] = heap[count.*];
    if (count.* > 0 and index < count.*) pushDown(heap, count.*, index, isMinLevel(index));
    return result;
}

fn writeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

fn insertionSort(values: *[MAX_HEAP_SIZE]i64, count: usize) void {
    if (count < 2) return;
    for (1..count) |index| {
        const value = values[index];
        var position = index;
        while (position > 0 and values[position - 1] > value) : (position -= 1) values[position] = values[position - 1];
        values[position] = value;
    }
}

export fn min_max_heap_double_ended(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2) return INVALID_RESULT;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 64) return INVALID_RESULT;
    const initial_count: usize = @intCast(values[0]);
    if (length < initial_count + 2) return INVALID_RESULT;
    const operations_value = values[initial_count + 1];
    if (operations_value < 0 or operations_value > 128) return INVALID_RESULT;
    const operation_count: usize = @intCast(operations_value);
    if (length != initial_count + 2 + 2 * operation_count) return INVALID_RESULT;
    for (values[1..initial_count + 1]) |value| if (value < -2_147_483_648 or value > 2_147_483_647) return INVALID_RESULT;
    for (0..operation_count) |op| {
        const opcode = values[initial_count + 2 + 2 * op];
        const argument = values[initial_count + 3 + 2 * op];
        if (opcode < 0 or opcode > 5) return INVALID_RESULT;
        if (opcode == 0) {
            if (argument < -2_147_483_648 or argument > 2_147_483_647) return INVALID_RESULT;
        } else if (argument != 0) return INVALID_RESULT;
    }

    var heap = [_]i64{0} ** MAX_HEAP_SIZE;
    var count = initial_count;
    for (0..initial_count) |index| heap[index] = values[index + 1];
    var build_index = initial_count / 2;
    while (build_index > 0) {
        build_index -= 1;
        pushDown(&heap, count, build_index, isMinLevel(build_index));
    }
    var events = [_]i64{0} ** MAX_OPERATIONS;
    var event_count: usize = 0;
    for (0..operation_count) |op| {
        const opcode = values[initial_count + 2 + 2 * op];
        const argument = values[initial_count + 3 + 2 * op];
        if (opcode == 0) addValue(&heap, &count, argument)
        else if (opcode == 1 or opcode == 3) {
            if (count == 0) return INVALID_RESULT;
            events[event_count] = if (opcode == 1) heap[0] else extractAt(&heap, &count, 0);
            event_count += 1;
        } else if (opcode == 2 or opcode == 4) {
            if (count == 0) return INVALID_RESULT;
            const index = maxIndex(&heap, count);
            events[event_count] = if (opcode == 2) heap[index] else extractAt(&heap, &count, index);
            event_count += 1;
        } else {
            events[event_count] = @intCast(count);
            event_count += 1;
        }
    }
    var sorted = heap;
    insertionSort(&sorted, count);
    const required = (2 + event_count + count) * 8;
    if (output == null or capacity < required) return CAPACITY_RESULT;
    const out = output.?;
    var offset: usize = 0;
    writeI64Le(out, offset, @intCast(event_count)); offset += 8;
    for (events[0..event_count]) |value| { writeI64Le(out, offset, value); offset += 8; }
    writeI64Le(out, offset, @intCast(count)); offset += 8;
    for (sorted[0..count]) |value| { writeI64Le(out, offset, value); offset += 8; }
    return @intCast(required);
}
