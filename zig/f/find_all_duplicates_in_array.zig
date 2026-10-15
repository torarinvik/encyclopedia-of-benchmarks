const MAX_LENGTH: usize = 100000;

fn siftDown(values: []i32, root_value: usize, end: usize) void {
    var root = root_value;
    while (root * 2 + 1 < end) {
        var child = root * 2 + 1;
        if (child + 1 < end and values[child] < values[child + 1]) child += 1;
        if (values[root] >= values[child]) break;
        const temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

fn heapSort(values: []i32) void {
    var start = values.len / 2;
    while (start > 0) {
        start -= 1;
        siftDown(values, start, values.len);
    }
    var ending = values.len;
    while (ending > 1) {
        ending -= 1;
        const temporary = values[0];
        values[0] = values[ending];
        values[ending] = temporary;
        siftDown(values, 0, ending);
    }
}

/// Sort a bounded copy and emit sorted duplicate values as little-endian i32s.
export fn find_all_duplicates_in_array(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    if (length == 0) return 0;

    var sorted: [MAX_LENGTH]i32 = undefined;
    for (0..length) |index| {
        if (values[index] < 1 or values[index] > @as(i64, @intCast(length))) return -1;
        sorted[index] = @intCast(values[index]);
    }
    heapSort(sorted[0..length]);

    var duplicate_count: usize = 0;
    var index: usize = 0;
    while (index < length) {
        var ending = index + 1;
        while (ending < length and sorted[ending] == sorted[index]) ending += 1;
        const frequency = ending - index;
        if (frequency > 2) return -1;
        if (frequency == 2) duplicate_count += 1;
        index = ending;
    }
    const output_bytes = duplicate_count * 4;
    if (output_capacity < output_bytes) return -2;
    var destination: usize = 0;
    index = 0;
    while (index < length) {
        var ending = index + 1;
        while (ending < length and sorted[ending] == sorted[index]) ending += 1;
        if (ending - index == 2) {
            const value: u32 = @intCast(sorted[index]);
            for (0..4) |byte| output[destination * 4 + byte] = @truncate(value >> @intCast(byte * 8));
            destination += 1;
        }
        index = ending;
    }
    return @intCast(duplicate_count);
}
